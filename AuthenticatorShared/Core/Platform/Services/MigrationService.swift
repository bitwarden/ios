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

    // MARK: Initialization

    /// Initialize a `DefaultMigrationService`.
    ///
    /// - Parameters:
    ///   - appSettingsStore: The service used by the application to persist app setting values.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - keychainRepository: The repository used to manage keychain items.
    ///
    init(
        appSettingsStore: AppSettingsStore,
        errorReporter: ErrorReporter,
        keychainRepository: KeychainRepository
    ) {
        self.appSettingsStore = appSettingsStore
        self.errorReporter = errorReporter
        self.keychainRepository = keychainRepository
    }

    // MARK: Private

    /// Performs migration 1.
    ///
    /// Notes:
    /// - Currently unused
    ///
    private func performMigration1() async throws {}
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
