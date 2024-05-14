import OSLog

// MARK: - MigrationService

/// A protocol for a service which handles app data migrations.
///
protocol MigrationService: AnyObject {
    /// Performs any necessary app data migrations.
    ///
    func performMigrations() async
}

// MARK: - DefaultMigrationService

/// A default implementation of `MigrationService` which handles app data migrations.
///
class DefaultMigrationService {
    // MARK: Properties

    /// The service used by the application to persist app setting values.
    let appSettingsStore: AppSettingsStore

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The repository used to manage keychain items.
    let keychainRepository: KeychainRepository

    /// The service name associated with the app's keychain items.
    let keychainServiceName: String

    /// The shared UserDefaults instance (NOTE: this should be the standard one just for the app,
    /// not one in the app group).
    let standardUserDefaults: UserDefaults

    // MARK: Initialization

    /// Initialize a `DefaultMigrationService`.
    ///
    /// - Parameters:
    ///   - appSettingsStore: The service used by the application to persist app setting values.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - keychainRepository: The repository used to manage keychain items.
    ///   - keychainServiceName: The service name associated with the app's keychain items.
    ///   - standardUserDefaults: The shared UserDefaults instance.
    ///
    init(
        appSettingsStore: AppSettingsStore,
        errorReporter: ErrorReporter,
        keychainRepository: KeychainRepository,
        keychainServiceName: String = Bundle.main.appIdentifier,
        standardUserDefaults: UserDefaults = .standard
    ) {
        self.appSettingsStore = appSettingsStore
        self.errorReporter = errorReporter
        self.keychainRepository = keychainRepository
        self.keychainServiceName = keychainServiceName
        self.standardUserDefaults = standardUserDefaults
    }

    // MARK: Private

    /// Performs migration 1.
    ///
    /// Notes:
    /// - Migrates account tokens from UserDefaults to Keychain.
    /// - Resets stored date values from Xamarin/Maui, which uses an incompatible format.
    /// - Clears all keychain values on a fresh app install.
    /// - Migrates AppCenter crash logging enabled to Crashlytics.
    ///
    private func performMigration1() async throws {
        // Migrate AppCenter crash logging enabled to Crashlytics.
        let isAppCenterCrashLoggingEnabled = standardUserDefaults.object(forKey: "MSAppCenterCrashesIsEnabled") as? Bool
        errorReporter.isEnabled = isAppCenterCrashLoggingEnabled ?? true

        guard var state = appSettingsStore.state else {
            // If state doesn't exist, this is a fresh install. Remove any persisted values in the
            // keychain from the previous install.
            try await keychainRepository.deleteAllItems()
            return
        }
        defer { appSettingsStore.state = state }

        for (accountId, account) in state.accounts {
            // Reset date values.
            appSettingsStore.setLastActiveTime(nil, userId: accountId)
            appSettingsStore.setLastSyncTime(nil, userId: accountId)
            appSettingsStore.setNotificationsLastRegistrationDate(nil, userId: accountId)

            // Migrate tokens to Keychain.
            let tokens = account._tokens
            state.accounts[accountId]?._tokens = nil

            guard let tokens else { continue }
            try await keychainRepository.setAccessToken(tokens.accessToken, userId: accountId)
            try await keychainRepository.setRefreshToken(tokens.refreshToken, userId: accountId)
        }
    }

    /// Performs migration 2.
    ///
    /// Notes:
    /// - Migrate Keychain items, migrating data in kSecAttrGeneric to kSecValueData.
    ///
    private func performMigration2() async throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecAttrService: keychainServiceName,
            kSecReturnData: true,
            kSecReturnAttributes: true,
        ] as CFDictionary
        var keychainItems: AnyObject?
        let status = SecItemCopyMatching(query, &keychainItems)
        guard status == errSecSuccess else {
            Logger.application.error("Error searching for keychain items: \(status)")
            return
        }

        if let keychainItems = keychainItems as? NSArray {
            for keychainItem in keychainItems {
                guard let itemDictionary = keychainItem as? NSDictionary else { continue }

                let query = [
                    kSecClass: kSecClassGenericPassword,
                    kSecAttrAccount: itemDictionary[kSecAttrAccount],
                    kSecAttrService: keychainServiceName,
                ] as CFDictionary

                var attributesToUpdate: [CFString: Any] = [
                    kSecAttrAccessGroup: Bundle.main.keychainAccessGroup,
                ]
                if let genericData = itemDictionary[kSecAttrGeneric] as? Data,
                   !genericData.isEmpty,
                   itemDictionary[kSecValueData] == nil {
                    // Migrate data from kSecAttrGeneric to kSecValueData.
                    attributesToUpdate[kSecValueData] = genericData
                    attributesToUpdate[kSecAttrGeneric] = Data()
                }

                let status = SecItemUpdate(query, attributesToUpdate as CFDictionary)
                guard status == errSecSuccess else {
                    Logger.application.error("Error updating keychain item: \(status)")
                    continue
                }
            }
        }
    }
}

extension DefaultMigrationService {
    /// The list of migrations that can be performed.
    var migrations: [() async throws -> Void] {
        [
            performMigration1,
            performMigration2,
        ]
    }

    /// Performs a single migration for a migration version number.
    ///
    /// - Note: `performMigrations()` should be used in almost all cases to perform the full set of
    ///     migrations. This exists to allow tests to perform a single migration.
    ///
    /// - Parameter version: The migration version to perform.
    ///
    func performMigration(version: Int) async throws {
        let migrationIndex = version - 1
        guard migrationIndex >= 0, migrationIndex < migrations.count else { return }
        try await migrations[migrationIndex]()
        appSettingsStore.migrationVersion = version
    }
}

extension DefaultMigrationService: MigrationService {
    func performMigrations() async {
        var migrationVersion = appSettingsStore.migrationVersion
        defer { appSettingsStore.migrationVersion = migrationVersion }

        do {
            for (migrationIndex, migration) in migrations.enumerated() {
                let version = migrationIndex + 1
                guard migrationVersion < version else { continue }

                try await migration()
                migrationVersion = version
                Logger.application.info("Completed data migration \(version)")
            }
        } catch {
            errorReporter.log(error: error)
        }
    }
}
