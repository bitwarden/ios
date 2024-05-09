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
    ///   - standardUserDefaults: The shared UserDefaults instance.
    ///
    init(
        appSettingsStore: AppSettingsStore,
        errorReporter: ErrorReporter,
        keychainRepository: KeychainRepository,
        standardUserDefaults: UserDefaults = .standard
    ) {
        self.appSettingsStore = appSettingsStore
        self.errorReporter = errorReporter
        self.keychainRepository = keychainRepository
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
}

extension DefaultMigrationService: MigrationService {
    func performMigrations() async {
        var migrationVersion = appSettingsStore.migrationVersion
        defer { appSettingsStore.migrationVersion = migrationVersion }

        // The list of migrations that can be performed.
        let migrations: [(version: Int, method: () async throws -> Void)] = [
            (1, performMigration1),
        ]

        do {
            for migration in migrations where migrationVersion < migration.version {
                try await migration.method()
                migrationVersion = migration.version
                Logger.application.info("Completed data migration \(migration.version)")
            }
        } catch {
            errorReporter.log(error: error)
        }
    }
}
