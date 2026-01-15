import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class MigrationServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appGroupUserDefaults: UserDefaults!
    var appSettingsStore: MockAppSettingsStore!
    var errorReporter: MockErrorReporter!
    var keychainRepository: MockKeychainRepository!
    var keychainService: MockKeychainService!
    var standardUserDefaults: UserDefaults!
    var subject: DefaultMigrationService!
    var userSessionStateService: MockUserSessionStateService!

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
        userSessionStateService = MockUserSessionStateService()

        for key in appGroupUserDefaults.dictionaryRepresentation().map(\.key) {
            appGroupUserDefaults.removeObject(forKey: key)
        }
        standardUserDefaults.removeObject(forKey: "MSAppCenterCrashesIsEnabled")
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
            keychainRepository: keychainRepository,
            keychainService: keychainService,
            keychainServiceName: testKeychainServiceName,
            standardUserDefaults: standardUserDefaults,
            userSessionStateService: userSessionStateService,
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
        userSessionStateService = nil
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
                        refreshToken: "REFRESH_TOKEN_1",
                    ),
                ),
            ],
            activeUserId: "1",
        )
        keychainRepository.setAccessTokenResult = .failure(KeychainServiceError.osStatusError(-1))

        await subject.performMigrations()

        XCTAssertEqual(appSettingsStore.migrationVersion, 0)
        XCTAssertEqual(errorReporter.errors as? [KeychainServiceError], [KeychainServiceError.osStatusError(-1)])
    }

    // MARK: Migration 1 (Tokens to Keychain)

    /// `performMigrations()` performs migration 1 and moves the user's tokens to the keychain.
    func test_performMigrations_1_withAccounts() async throws {
        appSettingsStore.migrationVersion = 0
        appSettingsStore.state = .fixture(
            accounts: [
                "1": .fixture(
                    tokens: Account.AccountTokens(
                        accessToken: "ACCESS_TOKEN_1",
                        refreshToken: "REFRESH_TOKEN_1",
                    ),
                ),
                "2": .fixture(
                    tokens: Account.AccountTokens(
                        accessToken: "ACCESS_TOKEN_2",
                        refreshToken: "REFRESH_TOKEN_2",
                    ),
                ),
            ],
            activeUserId: "1",
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
//            XCTAssertNil(appSettingsStore.lastActiveTime(userId: userId))
            XCTAssertNil(appSettingsStore.lastSyncTime(userId: userId))
            XCTAssertNil(appSettingsStore.notificationsLastRegistrationDate(userId: userId))
        }

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

    // MARK: Migration 2 (Update Keychain Security)

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
                nil,
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
            &copyResult,
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

    // MARK: Migration 3 (Remove MAUI Biometrics Integrity State)

    /// `performMigrations()` for migration 3 removes the integrity state values from MAUI.
    func test_performMigrations_3() async throws {
        appGroupUserDefaults.set(
            "integrity-state-app",
            forKey: "bwPreferencesStorage:biometricIntegritySource",
        )
        appGroupUserDefaults.set(
            "integrity-state-autofill",
            forKey: "bwPreferencesStorage:iOSAutoFillBiometricIntegritySource",
        )
        appGroupUserDefaults.set(
            "integrity-state-extension",
            forKey: "bwPreferencesStorage:iOSExtensionBiometricIntegritySource",
        )
        appGroupUserDefaults.set(
            "integrity-state-share-extension",
            forKey: "bwPreferencesStorage:iOSShareExtensionBiometricIntegritySource",
        )

        try await subject.performMigration(version: 3)

        // Previous values are removed.
        XCTAssertNil(
            appGroupUserDefaults.string(forKey: "bwPreferencesStorage:biometricIntegritySource"),
        )
        XCTAssertNil(
            appGroupUserDefaults.string(forKey: "bwPreferencesStorage:iOSAutoFillBiometricIntegritySource"),
        )
        XCTAssertNil(
            appGroupUserDefaults.string(forKey: "bwPreferencesStorage:iOSExtensionBiometricIntegritySource"),
        )
        XCTAssertNil(
            appGroupUserDefaults.string(forKey: "bwPreferencesStorage:iOSShareExtensionBiometricIntegritySource"),
        )
    }

    // MARK: Migration 4 (Remove Native Biometrics Integrity State)

    /// `performMigrations()` for migration 4 removes the native integrity state values.
    func test_performMigrations_4() async throws {
        func newKey(userId: String, extensionName: String?) -> String {
            [
                "bwPreferencesStorage:biometricIntegritySource_\(userId)_\(Bundle.main.appIdentifier)",
                extensionName,
            ]
            .compactMap(\.self)
            .joined(separator: ".")
        }

        for userId in ["1", "2"] {
            appGroupUserDefaults.set(
                "integrity-state-app",
                forKey: newKey(userId: userId, extensionName: nil),
            )
            appGroupUserDefaults.set(
                "integrity-state-autofill",
                forKey: newKey(userId: userId, extensionName: "autofill"),
            )
            appGroupUserDefaults.set(
                "integrity-state-find-login-action-extension",
                forKey: newKey(userId: userId, extensionName: "find-login-action-extension"),
            )
            appGroupUserDefaults.set(
                "integrity-state-share-extension",
                forKey: newKey(userId: userId, extensionName: "share-extension"),
            )
        }

        appSettingsStore.state = State(
            accounts: [
                "1": .fixture(),
                "2": .fixture(profile: .fixture(userId: "2")),
            ],
            activeUserId: "1",
        )

        try await subject.performMigration(version: 4)

        for userId in ["1", "2"] {
            XCTAssertNil(appGroupUserDefaults.string(
                forKey: newKey(userId: userId, extensionName: nil),
            ))
            XCTAssertNil(appGroupUserDefaults.string(
                forKey: newKey(userId: userId, extensionName: "autofill"),
            ))
            XCTAssertNil(appGroupUserDefaults.string(
                forKey: newKey(userId: userId, extensionName: "find-login-action-extension"),
            ))
            XCTAssertNil(appGroupUserDefaults.string(
                forKey: newKey(userId: userId, extensionName: "share-extension"),
            ))
        }
    }

    // MARK: Migration 5 (Migrate Session Data to Keychain)

    /// `performMigrations()` for migration 5 migrates lastActiveTime, unsuccessfulUnlockAttempts,
    /// and vaultTimeout from UserDefaults to the Keychain.
    func test_performMigrations_5() async throws { // swiftlint:disable:this function_body_length
        let lastActiveDate1 = Date(timeIntervalSince1970: 1_700_000_000)
        let lastActiveDate2 = Date(timeIntervalSince1970: 1_700_100_000)

        appGroupUserDefaults.set(
            String(lastActiveDate1.timeIntervalSince1970),
            forKey: "bwPreferencesStorage:lastActiveTime_1",
        )
        appGroupUserDefaults.set(
            String(lastActiveDate2.timeIntervalSince1970),
            forKey: "bwPreferencesStorage:lastActiveTime_2",
        )

        appGroupUserDefaults.set(
            "3",
            forKey: "bwPreferencesStorage:invalidUnlockAttempts_1",
        )
        appGroupUserDefaults.set(
            "5",
            forKey: "bwPreferencesStorage:invalidUnlockAttempts_2",
        )

        appGroupUserDefaults.set(
            "15",
            forKey: "bwPreferencesStorage:vaultTimeout_1",
        )
        appGroupUserDefaults.set(
            "-1",
            forKey: "bwPreferencesStorage:vaultTimeout_2",
        )

        appSettingsStore.state = State(
            accounts: [
                "1": .fixture(),
                "2": .fixture(profile: .fixture(userId: "2")),
            ],
            activeUserId: "1",
        )

        var setLastActiveTimeValue: [String: Date] = [:]
        var setUnsuccessfulUnlockAttemptsValue: [String: Int] = [:]
        var setVaultTimeoutValue: [String: SessionTimeoutValue] = [:]

        userSessionStateService.setLastActiveTimeClosure = { date, userId in
            guard let userId else { return }
            setLastActiveTimeValue[userId] = date
        }

        userSessionStateService.setUnsuccessfulUnlockAttemptsClosure = { attempts, userId in
            guard let userId else { return }
            setUnsuccessfulUnlockAttemptsValue[userId] = attempts
        }

        userSessionStateService.setVaultTimeoutClosure = { timeout, userId in
            guard let userId else { return }
            setVaultTimeoutValue[userId] = timeout
        }

        try await subject.performMigration(version: 5)

        // Verify values were migrated to the UserSessionStateService
        XCTAssertEqual(setLastActiveTimeValue["1"], lastActiveDate1)
        XCTAssertEqual(setLastActiveTimeValue["2"], lastActiveDate2)

        XCTAssertEqual(setUnsuccessfulUnlockAttemptsValue["1"], 3)
        XCTAssertEqual(setUnsuccessfulUnlockAttemptsValue["2"], 5)

        XCTAssertEqual(setVaultTimeoutValue["1"], .fifteenMinutes)
        XCTAssertEqual(setVaultTimeoutValue["2"], .onAppRestart)

        // Verify old values were removed from UserDefaults
        XCTAssertNil(appGroupUserDefaults.string(forKey: "bwPreferencesStorage:lastActiveTime_1"))
        XCTAssertNil(appGroupUserDefaults.string(forKey: "bwPreferencesStorage:lastActiveTime_2"))
        XCTAssertNil(appGroupUserDefaults.string(forKey: "bwPreferencesStorage:invalidUnlockAttempts_1"))
        XCTAssertNil(appGroupUserDefaults.string(forKey: "bwPreferencesStorage:invalidUnlockAttempts_2"))
        XCTAssertNil(appGroupUserDefaults.string(forKey: "bwPreferencesStorage:vaultTimeout_1"))
        XCTAssertNil(appGroupUserDefaults.string(forKey: "bwPreferencesStorage:vaultTimeout_2"))
    }

    /// `performMigrations()` for migration 5 handles missing values gracefully.
    func test_performMigrations_5_withMissingValues() async throws {
        let lastActiveDate1 = Date(timeIntervalSince1970: 1_700_000_000)
        appGroupUserDefaults.set(
            String(lastActiveDate1.timeIntervalSince1970),
            forKey: "bwPreferencesStorage:lastActiveTime_1",
        )

        appGroupUserDefaults.set(
            "5",
            forKey: "bwPreferencesStorage:invalidUnlockAttempts_2",
        )

        appGroupUserDefaults.set(
            "30",
            forKey: "bwPreferencesStorage:vaultTimeout_1",
        )

        appSettingsStore.state = State(
            accounts: [
                "1": .fixture(),
                "2": .fixture(profile: .fixture(userId: "2")),
            ],
            activeUserId: "1",
        )

        try await subject.performMigration(version: 5)

        // Verify only user 1's lastActiveTime was set
        XCTAssertEqual(userSessionStateService.setLastActiveTimeCallsCount, 1)
        XCTAssertEqual(userSessionStateService.setLastActiveTimeReceivedArguments?.userId, "1")

        // Verify only user 2's unsuccessfulUnlockAttempts was set
        XCTAssertEqual(userSessionStateService.setUnsuccessfulUnlockAttemptsCallsCount, 1)
        XCTAssertEqual(userSessionStateService.setUnsuccessfulUnlockAttemptsReceivedArguments?.userId, "2")

        // Verify only user 1's vaultTimeout was set
        XCTAssertEqual(userSessionStateService.setVaultTimeoutCallsCount, 1)
        XCTAssertEqual(userSessionStateService.setVaultTimeoutReceivedArguments?.userId, "1")
    }

    /// `performMigrations()` for migration 5 handles invalid data gracefully.
    func test_performMigrations_5_withInvalidData() async throws {
        appGroupUserDefaults.set(
            "not-a-valid-time-interval",
            forKey: "bwPreferencesStorage:lastActiveTime_1",
        )
        appGroupUserDefaults.set(
            "not-a-valid-number",
            forKey: "bwPreferencesStorage:invalidUnlockAttempts_1",
        )
        appGroupUserDefaults.set(
            "not-a-valid-timeout",
            forKey: "bwPreferencesStorage:vaultTimeout_1",
        )

        appSettingsStore.state = State(
            accounts: [
                "1": .fixture(),
            ],
            activeUserId: "1",
        )

        try await subject.performMigration(version: 5)

        // Verify invalid values were not migrated
        XCTAssertEqual(userSessionStateService.setLastActiveTimeCallsCount, 0)
        XCTAssertEqual(userSessionStateService.setUnsuccessfulUnlockAttemptsCallsCount, 0)
        XCTAssertEqual(userSessionStateService.setVaultTimeoutCallsCount, 0)

        // Verify UserDefaults values remain (since they weren't successfully migrated)
        XCTAssertNotNil(appGroupUserDefaults.string(forKey: "bwPreferencesStorage:lastActiveTime_1"))
        XCTAssertNotNil(appGroupUserDefaults.string(forKey: "bwPreferencesStorage:invalidUnlockAttempts_1"))
        XCTAssertNotNil(appGroupUserDefaults.string(forKey: "bwPreferencesStorage:vaultTimeout_1"))
    }

    /// `performMigrations()` for migration 5 handles custom vault timeout values.
    func test_performMigrations_5_withCustomVaultTimeout() async throws {
        appGroupUserDefaults.set(
            "120",
            forKey: "bwPreferencesStorage:vaultTimeout_1",
        )

        appSettingsStore.state = State(
            accounts: [
                "1": .fixture(),
            ],
            activeUserId: "1",
        )

        try await subject.performMigration(version: 5)

        // Verify custom timeout value was migrated correctly
        let actual = userSessionStateService.setVaultTimeoutReceivedArguments
        XCTAssertEqual(actual?.userId, "1")
        XCTAssertEqual(actual?.value, .custom(120))
        XCTAssertNil(appGroupUserDefaults.string(forKey: "bwPreferencesStorage:vaultTimeout_1"))
    }

    /// `performMigrations()` for migration 5 handles no existing accounts.
    func test_performMigrations_5_withNoAccounts() async throws {
        appSettingsStore.state = nil

        try await subject.performMigration(version: 5)

        XCTAssertEqual(appSettingsStore.migrationVersion, 5)
        XCTAssertEqual(userSessionStateService.setLastActiveTimeCallsCount, 0)
        XCTAssertEqual(userSessionStateService.setUnsuccessfulUnlockAttemptsCallsCount, 0)
        XCTAssertEqual(userSessionStateService.setVaultTimeoutCallsCount, 0)
    }
} // swiftlint:disable:this file_length
