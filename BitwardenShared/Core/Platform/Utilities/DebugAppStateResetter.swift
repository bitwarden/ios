#if DEBUG
import BitwardenKit
import CoreData
import Foundation
import OSLog

// MARK: - DebugAppStateResetter

/// Erases all of the app's stored state when it's launched with `-BWResetAppState YES`, so the app
/// starts as it does on a fresh install. Intended for UI automation; compiled into debug builds only.
///
/// It must run before `ServiceContainer` is created. Services read stored state and start
/// background work as soon as they exist, so erasing it underneath them leaves them acting on an
/// account that's gone.
///
/// What it leaves alone:
/// - The iOS notification permission, which is system state.
/// - The app group data shared with Authenticator. Keychain items shared with it are erased,
///   as they are by the cleanup the app runs on a fresh install.
/// - AutoFill credential identities: with no account left, `AutofillCredentialService` removes
///   them when it starts.
///
public struct DebugAppStateResetter {
    // MARK: Properties

    /// The app group's `UserDefaults`, holding the accounts and every app setting.
    let appGroupUserDefaults: UserDefaults

    /// The location of the Core Data store holding the vault data.
    let dataStoreURL: URL

    /// The directories holding files the app writes outside of its stores.
    let directories: [URL]

    /// The service used to access the device keychain.
    let keychainService: KeychainService

    /// The app's standard `UserDefaults`, which also exposes the launch arguments.
    let standardUserDefaults: UserDefaults

    // MARK: Type Methods

    /// The directories holding files the app writes outside of its stores: flight recorder logs,
    /// temporary files, vault exports, downloads and attachments.
    ///
    /// The caches and application support directories aren't emptied as a whole because
    /// third-party SDKs keep files there that can't be removed while the app runs.
    ///
    static func appFileDirectories(fileManager: FileManager = .default) -> [URL] {
        var directories = [
            try? fileManager.flightRecorderLogURL(),
            fileManager.temporaryDirectory,
            try? fileManager.exportedVaultURL(),
        ].compactMap(\.self)

        if let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            // Where `URLSession.download(from:)` moves downloaded files.
            directories.append(applicationSupport.appendingPathComponent("temp", isDirectory: true))
            // Attachments are stored in a directory per user.
            let userDirectories = (try? fileManager.contentsOfDirectory(
                at: applicationSupport,
                includingPropertiesForKeys: nil,
            )) ?? []
            directories += userDirectories.map { $0.appendingPathComponent("Attachments", isDirectory: true) }
        }
        return directories
    }

    /// Erases the app's state if it was launched with `-BWResetAppState YES`. Call it from the main
    /// app only, before creating `ServiceContainer`; extensions must never erase state.
    ///
    public static func resetIfRequested() {
        guard let appGroupUserDefaults = UserDefaults(suiteName: Bundle.main.groupIdentifier) else { return }
        let errors = DebugAppStateResetter(
            appGroupUserDefaults: appGroupUserDefaults,
            dataStoreURL: DataStore.persistedStoreURL,
            directories: appFileDirectories(),
            keychainService: DefaultKeychainService(),
            standardUserDefaults: .standard,
        ).resetIfRequested()

        for error in errors {
            Logger.application.error("BWResetAppState failed: \(error)")
        }
        // A partial reset would let one automated test contaminate the next, so stop here.
        assert(errors.isEmpty, "BWResetAppState failed: \(errors)")
    }

    // MARK: Methods

    /// Erases the app's state if the launch argument is set.
    ///
    /// - Returns: The errors of the steps that failed. Every step runs even if another fails.
    ///
    func resetIfRequested() -> [Error] {
        guard standardUserDefaults.bool(forKey: Constants.DebugLaunchArguments.resetAppState) else { return [] }

        var errors = [Error]()
        func attempt(_ step: () throws -> Void) {
            do {
                try step()
            } catch {
                errors.append(error)
            }
        }

        // Erasing the migration version too makes the app run its own fresh-install path next.
        removeAllValues(from: appGroupUserDefaults)
        removeAllValues(from: standardUserDefaults)

        attempt {
            try NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
                .destroyPersistentStore(at: dataStoreURL, type: .sqlite)
        }

        // The SSO cookie values are stored in the keychain.
        let itemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity,
        ]
        for itemClass in itemClasses {
            attempt { try keychainService.delete(query: [kSecClass: itemClass] as CFDictionary) }
        }

        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
        URLCache.shared.removeAllCachedResponses()

        for directory in directories {
            attempt { try removeContents(of: directory) }
        }

        return errors
    }

    // MARK: Private

    /// Removes every value stored in a `UserDefaults`' own domain. Values inherited from other
    /// domains, such as launch arguments, aren't affected.
    ///
    private func removeAllValues(from userDefaults: UserDefaults) {
        for key in userDefaults.dictionaryRepresentation().keys {
            userDefaults.removeObject(forKey: key)
        }
    }

    /// Removes everything inside a directory, keeping the directory itself. A missing directory
    /// is ignored.
    ///
    private func removeContents(of directory: URL) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: directory.path) else { return }
        for url in try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            try fileManager.removeItem(at: url)
        }
    }
}
#endif
