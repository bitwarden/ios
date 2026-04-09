import BitwardenKit
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

    /// The app's app group UserDefaults instance.
    let appGroupUserDefaults: UserDefaults

    /// The service used by the application to persist app setting values.
    let appSettingsStore: AppSettingsStore

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    // MARK: Initialization

    /// Initialize a `DefaultMigrationService`.
    ///
    /// - Parameters:
    ///   - appGroupUserDefaults: The app's app group UserDefaults instance.
    ///   - appSettingsStore: The service used by the application to persist app setting values.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///
    init(
        appGroupUserDefaults: UserDefaults = .standard,
        appSettingsStore: AppSettingsStore,
        errorReporter: ErrorReporter,
    ) {
        self.appGroupUserDefaults = appGroupUserDefaults
        self.appSettingsStore = appSettingsStore
        self.errorReporter = errorReporter
    }

    // MARK: Private

    /// Performs migration 1.
    ///
    /// Notes:
    /// - This was unused, but the app still recorded it having been run, so needs to remain
    /// despite doing nothing of value.
    private func performMigration1() async throws {}

    /// Performs migration 2.
    ///
    /// Notes:
    /// - Removes the integrity state values.
    ///
    private func performMigration2() async throws {
        let accountId = appSettingsStore.localUserId
        let appIdentifier = Bundle.main.appIdentifier

        appGroupUserDefaults.removeObject(
            forKey: "bwaPreferencesStorage:biometricIntegritySource_\(accountId)_\(appIdentifier)",
        )
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
