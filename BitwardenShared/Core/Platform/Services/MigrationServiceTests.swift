import XCTest

@testable import BitwardenShared

class MigrationServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appGroupUserDefaults: UserDefaults!
    var appSettingsStore: MockAppSettingsStore!
    var errorReporter: MockErrorReporter!
    var keychainRepository: MockKeychainRepository!
    var keychainService: MockKeychainService!
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
        keychainRepository = MockKeychainRepository()
        keychainService = MockKeychainService()
        standardUserDefaults = UserDefaults(suiteName: "test")

        for key in appGroupUserDefaults.dictionaryRepresentation().map(\.key) {
            appGroupUserDefaults.removeObject(forKey: key)
        }
        standardUserDefaults.removeObject(forKey: "MSAppCenterCrashesIsEnabled")
        SecItemDelete(
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: testKeychainServiceName,
            ] as CFDictionary
        )

        subject = DefaultMigrationService(
            appGroupUserDefaults: appGroupUserDefaults,
            appSettingsStore: appSettingsStore,
            errorReporter: errorReporter,
            keychainRepository: keychainRepository,
            keychainService: keychainService,
            keychainServiceName: testKeychainServiceName,
            standardUserDefaults: standardUserDefaults
        )
    }

    override func tearDown() {
        super.tearDown()

        appGroupUserDefaults = nil
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
                    kSecAttrService: testKeychainServiceName,
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
                kSecAttrService: testKeychainServiceName,
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

    /// `performMigrations()` for migration 3 migrates the integrity state values.
    func test_performMigrations_3() async throws {
        appGroupUserDefaults.set(
            "integrity-state-autofill",
            forKey: "bwPreferencesStorage:iOSAutoFillBiometricIntegritySource"
        )
        appGroupUserDefaults.set(
            "integrity-state-extension",
            forKey: "bwPreferencesStorage:iOSExtensionBiometricIntegritySource"
        )
        appGroupUserDefaults.set(
            "integrity-state-share-extension",
            forKey: "bwPreferencesStorage:iOSShareExtensionBiometricIntegritySource"
        )
        appSettingsStore.state = State(
            accounts: [
                "1": .fixture(),
                "2": .fixture(profile: .fixture(userId: "2")),
            ],
            activeUserId: "1"
        )

        try await subject.performMigration(version: 3)

        func newKey(userId: String, extensionName: String) -> String {
            "bwPreferencesStorage:biometricIntegritySource_\(userId)_\(Bundle.main.appIdentifier).\(extensionName)"
        }

        for userId in 1 ... 2 {
            let userId = String(userId)

            let autofillKey = newKey(userId: userId, extensionName: "autofill")
            XCTAssertEqual(appGroupUserDefaults.string(forKey: autofillKey), "integrity-state-autofill")

            let extensionKey = newKey(userId: userId, extensionName: "find-login-action-extension")
            XCTAssertEqual(appGroupUserDefaults.string(forKey: extensionKey), "integrity-state-extension")

            let shareExtensionKey = newKey(userId: userId, extensionName: "share-extension")
            XCTAssertEqual(appGroupUserDefaults.string(forKey: shareExtensionKey), "integrity-state-share-extension")
        }

        // Previous values are removed.
        XCTAssertNil(
            appGroupUserDefaults.string(forKey: "bwPreferencesStorage:iOSAutoFillBiometricIntegritySource")
        )
        XCTAssertNil(
            appGroupUserDefaults.string(forKey: "bwPreferencesStorage:iOSExtensionBiometricIntegritySource")
        )
        XCTAssertNil(
            appGroupUserDefaults.string(forKey: "bwPreferencesStorage:iOSShareExtensionBiometricIntegritySource")
        )
    }

    /// `performMigrations()` for migration 3 removes the previous values if there's no accounts to migrate.
    func test_performMigrations_3_noAccounts() async throws {
        appGroupUserDefaults.set(
            "integrity-state-autofill",
            forKey: "bwPreferencesStorage:iOSAutoFillBiometricIntegritySource"
        )
        appGroupUserDefaults.set(
            "integrity-state-extension",
            forKey: "bwPreferencesStorage:iOSExtensionBiometricIntegritySource"
        )
        appGroupUserDefaults.set(
            "integrity-state-share-extension",
            forKey: "bwPreferencesStorage:iOSShareExtensionBiometricIntegritySource"
        )

        try await subject.performMigration(version: 3)

        // Previous values are removed.
        XCTAssertNil(
            appGroupUserDefaults.string(forKey: "bwPreferencesStorage:iOSAutoFillBiometricIntegritySource")
        )
        XCTAssertNil(
            appGroupUserDefaults.string(forKey: "bwPreferencesStorage:iOSExtensionBiometricIntegritySource")
        )
        XCTAssertNil(
            appGroupUserDefaults.string(forKey: "bwPreferencesStorage:iOSShareExtensionBiometricIntegritySource")
        )
    }

    /// `performMigrations()` for migration 3 migrates the integrity state values, skipping any
    /// keys which have new values.
    func test_performMigrations_3_skipsNewKeys() async throws { // swiftlint:disable:this function_body_length
        func newKey(userId: String, extensionName: String) -> String {
            "bwPreferencesStorage:biometricIntegritySource_\(userId)_\(Bundle.main.appIdentifier).\(extensionName)"
        }

        appGroupUserDefaults.set(
            "integrity-state-autofill",
            forKey: "bwPreferencesStorage:iOSAutoFillBiometricIntegritySource"
        )
        appGroupUserDefaults.set(
            "integrity-state-extension",
            forKey: "bwPreferencesStorage:iOSExtensionBiometricIntegritySource"
        )
        appGroupUserDefaults.set(
            "integrity-state-share-extension",
            forKey: "bwPreferencesStorage:iOSShareExtensionBiometricIntegritySource"
        )

        // User 1 already has new integrity state values set.
        appGroupUserDefaults.set(
            "new-integrity-state-autofill",
            forKey: newKey(userId: "1", extensionName: "autofill")
        )
        appGroupUserDefaults.set(
            "new-integrity-state-extension",
            forKey: newKey(userId: "1", extensionName: "find-login-action-extension")
        )
        appGroupUserDefaults.set(
            "new-integrity-state-share-extension",
            forKey: newKey(userId: "1", extensionName: "share-extension")
        )

        appSettingsStore.state = State(
            accounts: [
                "1": .fixture(),
                "2": .fixture(profile: .fixture(userId: "2")),
            ],
            activeUserId: "1"
        )

        try await subject.performMigration(version: 3)

        // User 1 keeps newer values.
        let autofillKey1 = newKey(userId: "1", extensionName: "autofill")
        XCTAssertEqual(appGroupUserDefaults.string(forKey: autofillKey1), "new-integrity-state-autofill")

        let extensionKey1 = newKey(userId: "1", extensionName: "find-login-action-extension")
        XCTAssertEqual(appGroupUserDefaults.string(forKey: extensionKey1), "new-integrity-state-extension")

        let shareExtensionKey1 = newKey(userId: "1", extensionName: "share-extension")
        XCTAssertEqual(appGroupUserDefaults.string(forKey: shareExtensionKey1), "new-integrity-state-share-extension")

        // User 2 gets migrated values.
        let autofillKey2 = newKey(userId: "2", extensionName: "autofill")
        XCTAssertEqual(appGroupUserDefaults.string(forKey: autofillKey2), "integrity-state-autofill")

        let extensionKey2 = newKey(userId: "2", extensionName: "find-login-action-extension")
        XCTAssertEqual(appGroupUserDefaults.string(forKey: extensionKey2), "integrity-state-extension")

        let shareExtensionKey2 = newKey(userId: "2", extensionName: "share-extension")
        XCTAssertEqual(appGroupUserDefaults.string(forKey: shareExtensionKey2), "integrity-state-share-extension")

        // Previous values are removed.
        XCTAssertNil(
            appGroupUserDefaults.string(forKey: "bwPreferencesStorage:iOSAutoFillBiometricIntegritySource")
        )
        XCTAssertNil(
            appGroupUserDefaults.string(forKey: "bwPreferencesStorage:iOSExtensionBiometricIntegritySource")
        )
        XCTAssertNil(
            appGroupUserDefaults.string(forKey: "bwPreferencesStorage:iOSShareExtensionBiometricIntegritySource")
        )
    }
}
