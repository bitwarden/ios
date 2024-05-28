import XCTest

@testable import BitwardenShared

class MigrationServiceTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var errorReporter: MockErrorReporter!
    var keychainRepository: MockKeychainRepository!
    var keychainService: MockKeychainService!
    var standardUserDefaults: UserDefaults!
    var subject: DefaultMigrationService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        errorReporter = MockErrorReporter()
        keychainRepository = MockKeychainRepository()
        keychainService = MockKeychainService()
        standardUserDefaults = UserDefaults(suiteName: "test")

        standardUserDefaults.removeObject(forKey: "MSAppCenterCrashesIsEnabled")
        SecItemDelete([kSecClass: kSecClassGenericPassword] as CFDictionary)

        subject = DefaultMigrationService(
            appSettingsStore: appSettingsStore,
            errorReporter: errorReporter,
            keychainRepository: keychainRepository,
            keychainService: keychainService,
            keychainServiceName: "com.bitwarden.test",
            standardUserDefaults: standardUserDefaults
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        errorReporter = nil
        keychainRepository = nil
        keychainService = nil
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

    /// `performMigrations()` logs an error to the error reporter if one occurs.
    func test_performMigrations_error() async throws {
        appSettingsStore.migrationVersion = 0
        appSettingsStore.state = .fixture(
            accounts: [
                "1": .fixture(
                    tokens: Account.AccountTokens(
                        accessToken: "ACCESS_TOKEN_1",
                        refreshToken: "REFRESH_TOKEN_1"
                    )
                ),
            ],
            activeUserId: "1"
        )
        keychainRepository.setAccessTokenResult = .failure(KeychainServiceError.osStatusError(-1))

        await subject.performMigrations()

        XCTAssertEqual(appSettingsStore.migrationVersion, 0)
        XCTAssertEqual(errorReporter.errors as? [KeychainServiceError], [KeychainServiceError.osStatusError(-1)])
    }

    /// `performMigrations()` performs migration 1 and moves the user's tokens to the keychain.
    func test_performMigrations_1_withAccounts() async throws {
        appSettingsStore.biometricIntegrityStateLegacy = "1234"
        appSettingsStore.migrationVersion = 0
        appSettingsStore.state = .fixture(
            accounts: [
                "1": .fixture(
                    tokens: Account.AccountTokens(
                        accessToken: "ACCESS_TOKEN_1",
                        refreshToken: "REFRESH_TOKEN_1"
                    )
                ),
                "2": .fixture(
                    tokens: Account.AccountTokens(
                        accessToken: "ACCESS_TOKEN_2",
                        refreshToken: "REFRESH_TOKEN_2"
                    )
                ),
            ],
            activeUserId: "1"
        )
        for userId in ["1", "2"] {
            appSettingsStore.lastActiveTime[userId] = Date()
            appSettingsStore.lastSyncTimeByUserId[userId] = Date()
            appSettingsStore.notificationsLastRegistrationDates[userId] = Date()
        }

        try await subject.performMigration(version: 1)

        XCTAssertEqual(appSettingsStore.migrationVersion, 1)

        let account1 = try XCTUnwrap(appSettingsStore.state?.accounts["1"])
        XCTAssertNil(account1._tokens)
        let account2 = try XCTUnwrap(appSettingsStore.state?.accounts["2"])
        XCTAssertNil(account2._tokens)

        try XCTAssertEqual(keychainRepository.getValue(for: .accessToken(userId: "1")), "ACCESS_TOKEN_1")
        try XCTAssertEqual(keychainRepository.getValue(for: .refreshToken(userId: "1")), "REFRESH_TOKEN_1")
        try XCTAssertEqual(keychainRepository.getValue(for: .accessToken(userId: "2")), "ACCESS_TOKEN_2")
        try XCTAssertEqual(keychainRepository.getValue(for: .refreshToken(userId: "2")), "REFRESH_TOKEN_2")

        for userId in ["1", "2"] {
            XCTAssertEqual(appSettingsStore.biometricIntegrityState(userId: userId), "1234")
            XCTAssertNil(appSettingsStore.lastActiveTime(userId: userId))
            XCTAssertNil(appSettingsStore.lastSyncTime(userId: userId))
            XCTAssertNil(appSettingsStore.notificationsLastRegistrationDate(userId: userId))
        }

        XCTAssertNil(appSettingsStore.biometricIntegrityStateLegacy)
        XCTAssertFalse(keychainRepository.deleteAllItemsCalled)

        XCTAssertTrue(errorReporter.isEnabled)
    }

    /// `performMigrations()` for migration 1 handles migrating the crashes enabled key from
    /// AppCenter when it's set to `false`.
    func test_performMigrations_1_withAppCenterCrashesKey_false() async throws {
        appSettingsStore.migrationVersion = 0
        standardUserDefaults.setValue(false, forKey: "MSAppCenterCrashesIsEnabled")
        try await subject.performMigration(version: 1)
        XCTAssertFalse(errorReporter.isEnabled)
    }

    /// `performMigrations()` for migration 1 handles migrating the crashes enabled key from
    /// AppCenter when it's set to `true`.
    func test_performMigrations_1_withAppCenterCrashesKey_true() async throws {
        appSettingsStore.migrationVersion = 0
        standardUserDefaults.setValue(true, forKey: "MSAppCenterCrashesIsEnabled")
        try await subject.performMigration(version: 1)
        XCTAssertTrue(errorReporter.isEnabled)
    }

    /// `performMigrations()` for migration 1 handles no existing accounts.
    func test_performMigrations_1_withNoAccounts() async throws {
        appSettingsStore.migrationVersion = 0
        appSettingsStore.state = nil

        try await subject.performMigration(version: 1)

        XCTAssertEqual(appSettingsStore.migrationVersion, 1)
        XCTAssertNil(appSettingsStore.state)
        XCTAssertTrue(keychainRepository.deleteAllItemsCalled)
        XCTAssertTrue(errorReporter.isEnabled)
    }

    /// `performMigrations()` for migration 2 migrates keychain data in kSecAttrGeneric to kSecValueData.
    func test_performMigrations_2() async throws {
        let itemsToAdd: [(account: String, value: String)] = [
            ("TEST_ACCOUNT_1", "secret"),
            ("TEST_ACCOUNT_2", "password"),
        ]
        for item in itemsToAdd {
            SecItemAdd(
                [
                    kSecClass: kSecClassGenericPassword,
                    kSecAttrAccount: item.account,
                    kSecAttrService: "com.bitwarden.test",
                    kSecAttrGeneric: Data(item.value.utf8),
                ] as CFDictionary,
                nil
            )
        }

        try await subject.performMigration(version: 2)

        var copyResult: AnyObject?
        SecItemCopyMatching(
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: "com.bitwarden.test",
                kSecMatchLimit: kSecMatchLimitAll,
                kSecReturnData: true,
                kSecReturnAttributes: true,
            ] as CFDictionary,
            &copyResult
        )

        let keychainItems = try XCTUnwrap(copyResult as? [[CFString: Any]])
        XCTAssertEqual(keychainItems.count, 2)

        let item1 = try XCTUnwrap(keychainItems[0])
        XCTAssertEqual(item1[kSecAttrAccessGroup] as? String, Bundle.main.keychainAccessGroup)
        XCTAssertEqual(item1[kSecAttrAccount] as? String, "TEST_ACCOUNT_1")
        XCTAssertEqual(item1[kSecAttrGeneric] as? Data, Data())
        XCTAssertEqual(item1[kSecValueData] as? Data, Data("secret".utf8))

        let item2 = try XCTUnwrap(keychainItems[1])
        XCTAssertEqual(item2[kSecAttrAccessGroup] as? String, Bundle.main.keychainAccessGroup)
        XCTAssertEqual(item2[kSecAttrAccount] as? String, "TEST_ACCOUNT_2")
        XCTAssertEqual(item2[kSecAttrGeneric] as? Data, Data())
        XCTAssertEqual(item2[kSecValueData] as? Data, Data("password".utf8))

        XCTAssertEqual(appSettingsStore.migrationVersion, 2)
    }
}
