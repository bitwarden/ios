import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import AuthenticatorShared
@testable import AuthenticatorSharedMocks

class MigrationServiceTests: BitwardenTestCase {
    // MARK: Properties

    var appGroupUserDefaults: UserDefaults!
    var appSettingsStore: MockAppSettingsStore!
    var errorReporter: MockErrorReporter!
    var standardUserDefaults: UserDefaults!
    var subject: DefaultMigrationService!

    /// A keychain service name to use during tests to avoid corrupting the app's keychain items.
    private let testKeychainServiceName = "com.bitwarden.test"

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appGroupUserDefaults = UserDefaults(suiteName: "test-app-group")
        appSettingsStore = MockAppSettingsStore()
        errorReporter = MockErrorReporter()
        standardUserDefaults = UserDefaults(suiteName: "test")

        for key in appGroupUserDefaults.dictionaryRepresentation().map(\.key) {
            appGroupUserDefaults.removeObject(forKey: key)
        }

        SecItemDelete(
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: testKeychainServiceName,
            ] as CFDictionary,
        )

        subject = DefaultMigrationService(
            appGroupUserDefaults: appGroupUserDefaults,
            appSettingsStore: appSettingsStore,
            errorReporter: errorReporter,
        )
    }

    override func tearDown() {
        super.tearDown()

        appGroupUserDefaults = nil
        appSettingsStore = nil
        errorReporter = nil
        standardUserDefaults = nil
        subject = nil
    }

    // MARK: Tests

    /// `performMigrations()` performs all migrations and updates the migration version.
    func test_performMigrations() async throws {
        appSettingsStore.migrationVersion = 0

        await subject.performMigrations()

        XCTAssertEqual(appSettingsStore.migrationVersion, subject.migrations.count)
    }

    // MARK: Migration 2 (Remove Biometrics Integrity State)

    /// `performMigrations()` for migration 2 removes the native integrity state values.
    func test_performMigrations_2() async throws {
        func newKey(userId: String) -> String {
            "bwaPreferencesStorage:biometricIntegritySource_\(userId)_\(Bundle.main.appIdentifier)"
        }

        appGroupUserDefaults.set(
            "integrity-state",
            forKey: newKey(userId: "1"),
        )

        appSettingsStore.localUserId = "1"

        try await subject.performMigration(version: 2)

        XCTAssertNil(
            appGroupUserDefaults.string(
                forKey: newKey(userId: "1"),
            ),
        )
    }
}
