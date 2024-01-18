import XCTest

@testable import BitwardenShared

// MARK: - AppSettingsStoreTests

// swiftlint:disable file_length

class AppSettingsStoreTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var subject: AppSettingsStore!
    var userDefaults: UserDefaults!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        userDefaults = UserDefaults(suiteName: "AppSettingsStoreTests")

        userDefaults.dictionaryRepresentation()
            .keys
            .filter { $0.hasPrefix("bwPreferencesStorage:") }
            .forEach { key in
                userDefaults.removeObject(forKey: key)
            }

        subject = DefaultAppSettingsStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
        userDefaults = nil
    }

    // MARK: Tests

    /// `appId` returns `nil` if there isn't a previously stored value.
    func test_appId_isInitiallyNil() {
        XCTAssertNil(subject.appId)
    }

    /// `appId` can be used to get and set the persisted value in user defaults.
    func test_appId_withValue() {
        subject.appId = "📱"
        XCTAssertEqual(subject.appId, "📱")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:appId"), "📱")

        subject.appId = "☎️"
        XCTAssertEqual(subject.appId, "☎️")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:appId"), "☎️")

        subject.appId = nil
        XCTAssertNil(subject.appId)
        XCTAssertNil(userDefaults.string(forKey: "bwPreferencesStorage:appId"))
    }

    /// `allowSyncOnRefresh(userId:)` returns `false` if there isn't a previously stored value.
    func test_allowSyncOnRefresh_isInitiallyFalse() {
        XCTAssertFalse(subject.allowSyncOnRefresh(userId: "-1"))
    }

    /// `allowSyncOnRefresh(userId:)` can be used to get the allow sync on refresh value for a user.
    func test_allowSyncOnRefresh_withValue() {
        subject.setAllowSyncOnRefresh(true, userId: "1")
        subject.setAllowSyncOnRefresh(false, userId: "2")

        XCTAssertTrue(subject.allowSyncOnRefresh(userId: "1"))
        XCTAssertFalse(subject.allowSyncOnRefresh(userId: "2"))
        XCTAssertTrue(userDefaults.bool(forKey: "bwPreferencesStorage:syncOnRefresh_1"))
        XCTAssertFalse(userDefaults.bool(forKey: "bwPreferencesStorage:syncOnRefresh_w"))
    }

    /// `appLocale`is initially `nil`.
    func test_appLocale_isInitiallyNil() {
        XCTAssertNil(subject.appLocale)
    }

    /// `appLocale` can be used to get and set the persisted value in user defaults.
    func test_appLocale_withValue() {
        subject.appLocale = "th"
        XCTAssertEqual(subject.appLocale, "th")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:appLocale"), "th")

        subject.appLocale = nil
        XCTAssertNil(subject.appLocale)
        XCTAssertNil(userDefaults.string(forKey: "bwPreferencesStorage:appLocale"))
    }

    /// `appTheme` returns `nil` if there isn't a previously stored value.
    func test_appTheme_isInitiallyNil() {
        XCTAssertNil(subject.appTheme)
    }

    /// `appTheme` can be used to get and set the persisted value in user defaults.
    func test_appTheme_withValue() {
        subject.appTheme = "light"
        XCTAssertEqual(subject.appTheme, "light")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:theme"), "light")

        subject.appTheme = nil
        XCTAssertNil(subject.appTheme)
        XCTAssertNil(userDefaults.string(forKey: "bwPreferencesStorage:theme"))
    }

    /// `clearClipboardValue(userId:)` returns `.never` if there isn't a previously stored value.
    func test_clearClipboardValue_isInitiallyNever() {
        XCTAssertEqual(subject.clearClipboardValue(userId: "0"), .never)
    }

    /// `clearClipboardValue(userId:)` can be used to get the clear clipboard value for a user.
    func test_clearClipboardValue_withValue() {
        subject.setClearClipboardValue(.tenSeconds, userId: "1")
        subject.setClearClipboardValue(.never, userId: "2")

        XCTAssertEqual(subject.clearClipboardValue(userId: "1"), .tenSeconds)
        XCTAssertEqual(subject.clearClipboardValue(userId: "2"), .never)
        XCTAssertEqual(userDefaults.integer(forKey: "bwPreferencesStorage:clearClipboard_1"), 10)
        XCTAssertEqual(userDefaults.integer(forKey: "bwPreferencesStorage:clearClipboard_2"), -1)
    }

    /// `connectToWatch(userId:)` returns false if there isn't a previously stored value.
    func test_connectToWatch_isInitiallyFalse() {
        XCTAssertFalse(subject.connectToWatch(userId: "0"))
    }

    /// `connectToWatch(userId:)` can be used to get the connect to watch value for a user.
    func test_connectToWatch_withValue() {
        subject.setConnectToWatch(true, userId: "1")
        subject.setConnectToWatch(false, userId: "2")

        XCTAssertTrue(subject.connectToWatch(userId: "1"))
        XCTAssertFalse(subject.connectToWatch(userId: "2"))
        XCTAssertTrue(userDefaults.bool(forKey: "bwPreferencesStorage:shouldConnectToWatch_1"))
        XCTAssertFalse(userDefaults.bool(forKey: "bwPreferencesStorage:shouldConnectToWatch_2"))
    }

    /// `defaultUriMatchType(userId:)` returns `nil` if there isn't a previously stored value.
    func test_defaultUriMatchType_isInitiallyNil() {
        XCTAssertNil(subject.defaultUriMatchType(userId: "-1"))
    }

    /// `defaultUriMatchType(userId:)` can be used to get the default URI match type value for a user.
    func test_defaultUriMatchType_withValue() {
        subject.setDefaultUriMatchType(.exact, userId: "1")
        subject.setDefaultUriMatchType(.host, userId: "2")

        XCTAssertEqual(subject.defaultUriMatchType(userId: "1"), .exact)
        XCTAssertEqual(subject.defaultUriMatchType(userId: "2"), .host)
        XCTAssertEqual(userDefaults.integer(forKey: "bwPreferencesStorage:defaultUriMatch_1"), 3)
        XCTAssertEqual(userDefaults.integer(forKey: "bwPreferencesStorage:defaultUriMatch_2"), 1)
    }

    /// `disableAutoTotpCopy(userId:)` returns `false` if there isn't a previously stored value.
    func test_disableAutoTotpCopy_isInitiallyNil() {
        XCTAssertFalse(subject.disableAutoTotpCopy(userId: "-1"))
    }

    /// `disableAutoTotpCopy(userId:)` can be used to get the disable auto-copy TOTP value for a user.
    func test_disableAutoTotpCopy_withValue() {
        subject.setDisableAutoTotpCopy(true, userId: "1")
        subject.setDisableAutoTotpCopy(false, userId: "2")

        XCTAssertTrue(subject.disableAutoTotpCopy(userId: "1"))
        XCTAssertFalse(subject.disableAutoTotpCopy(userId: "2"))
        XCTAssertTrue(userDefaults.bool(forKey: "bwPreferencesStorage:disableAutoTotpCopy_1"))
        XCTAssertFalse(userDefaults.bool(forKey: "bwPreferencesStorage:disableAutoTotpCopy_2"))
    }

    /// `disableWebIcons` returns `false` if there isn't a previously stored value.
    func test_disableWebIcons_isInitiallyFalse() {
        XCTAssertFalse(subject.disableWebIcons)
    }

    /// `disableWebIcons` can be used to get and set the persisted value in user defaults.
    func test_disableWebIcons_withValue() {
        subject.disableWebIcons = true
        XCTAssertTrue(subject.disableWebIcons)
        XCTAssertTrue(userDefaults.bool(forKey: "bwPreferencesStorage:disableFavicon"))

        subject.disableWebIcons = false
        XCTAssertFalse(subject.disableWebIcons)
        XCTAssertFalse(userDefaults.bool(forKey: "bwPreferencesStorage:disableFavicon"))
    }

    /// `encryptedPrivateKey(userId:)` returns `nil` if there isn't a previously stored value.
    func test_encryptedPrivateKey_isInitiallyNil() {
        XCTAssertNil(subject.encryptedPrivateKey(userId: "-1"))
    }

    /// `encryptedPrivateKey(userId:)` can be used to get the encrypted private key for a user.
    func test_encryptedPrivateKey_withValue() {
        subject.setEncryptedPrivateKey(key: "1:PRIVATE_KEY", userId: "1")
        subject.setEncryptedPrivateKey(key: "2:PRIVATE_KEY", userId: "2")

        XCTAssertEqual(subject.encryptedPrivateKey(userId: "1"), "1:PRIVATE_KEY")
        XCTAssertEqual(subject.encryptedPrivateKey(userId: "2"), "2:PRIVATE_KEY")
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:encPrivateKey_1"),
            "1:PRIVATE_KEY"
        )
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:encPrivateKey_2"),
            "2:PRIVATE_KEY"
        )

        subject.setEncryptedPrivateKey(key: "1:PRIVATE_KEY_NEW", userId: "1")
        subject.setEncryptedPrivateKey(key: "2:PRIVATE_KEY_NEW", userId: "2")

        XCTAssertEqual(subject.encryptedPrivateKey(userId: "1"), "1:PRIVATE_KEY_NEW")
        XCTAssertEqual(subject.encryptedPrivateKey(userId: "2"), "2:PRIVATE_KEY_NEW")
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:encPrivateKey_1"),
            "1:PRIVATE_KEY_NEW"
        )
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:encPrivateKey_2"),
            "2:PRIVATE_KEY_NEW"
        )
    }

    /// `encryptedUserKey(userId:)` returns `nil` if there isn't a previously stored value.
    func test_encryptedUserKey_isInitiallyNil() {
        XCTAssertNil(subject.encryptedUserKey(userId: "-1"))
    }

    /// `encryptedUserKey(userId:)` can be used to get the encrypted user key for a user.
    func test_encryptedUserKey_withValue() {
        subject.setEncryptedUserKey(key: "1:USER_KEY", userId: "1")
        subject.setEncryptedUserKey(key: "2:USER_KEY", userId: "2")

        XCTAssertEqual(subject.encryptedUserKey(userId: "1"), "1:USER_KEY")
        XCTAssertEqual(subject.encryptedUserKey(userId: "2"), "2:USER_KEY")
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:masterKeyEncryptedUserKey_1"),
            "1:USER_KEY"
        )
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:masterKeyEncryptedUserKey_2"),
            "2:USER_KEY"
        )

        subject.setEncryptedUserKey(key: "1:USER_KEY_NEW", userId: "1")
        subject.setEncryptedUserKey(key: "2:USER_KEY_NEW", userId: "2")

        XCTAssertEqual(subject.encryptedUserKey(userId: "1"), "1:USER_KEY_NEW")
        XCTAssertEqual(subject.encryptedUserKey(userId: "2"), "2:USER_KEY_NEW")
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:masterKeyEncryptedUserKey_1"),
            "1:USER_KEY_NEW"
        )
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:masterKeyEncryptedUserKey_2"),
            "2:USER_KEY_NEW"
        )
    }

    /// `lastActiveTime(userId:)` can be used to get the last active time for a user.
    func test_lastActiveTime() {
        let date1 = Date(year: 2023, month: 12, day: 1)
        subject.setLastActiveTime(date1, userId: "1")

        XCTAssertEqual(subject.lastActiveTime(userId: "1"), date1)
        XCTAssertEqual(userDefaults.double(forKey: "bwPreferencesStorage:lastActiveTime_1"), 723_081_600.0)
    }

    /// `lastUserShouldConnectToWatch` returns `false` if there isn't a previously stored value.
    func test_lastUserShouldConnectToWatch_isInitiallyFalse() {
        XCTAssertFalse(subject.lastUserShouldConnectToWatch)
    }

    /// `lastUserShouldConnectToWatch` can be used to get the last connect to watch value.
    func test_lastUserShouldConnectToWatch_withValue() {
        subject.lastUserShouldConnectToWatch = true
        XCTAssertTrue(userDefaults.bool(forKey: "bwPreferencesStorage:lastUserShouldConnectToWatch"))

        subject.lastUserShouldConnectToWatch = false
        XCTAssertFalse(userDefaults.bool(forKey: "bwPreferencesStorage:lastUserShouldConnectToWatch"))
    }

    /// `lastSyncTime(userId:)` returns `nil` if there isn't a previously stored value.
    func test_lastSyncTime_isInitiallyNil() {
        XCTAssertNil(subject.lastSyncTime(userId: "-1"))
    }

    /// `lastSyncTime(userId:)` can be used to get the last sync time for a user.
    func test_lastSyncTime_withValue() {
        let date1 = Date(year: 2023, month: 12, day: 1)
        let date2 = Date(year: 2023, month: 10, day: 2)

        subject.setLastSyncTime(date1, userId: "1")
        subject.setLastSyncTime(date2, userId: "2")

        XCTAssertEqual(subject.lastSyncTime(userId: "1"), date1)
        XCTAssertEqual(subject.lastSyncTime(userId: "2"), date2)
        XCTAssertEqual(userDefaults.double(forKey: "bwPreferencesStorage:lastSync_1"), 1_701_388_800.0)
        XCTAssertEqual(userDefaults.double(forKey: "bwPreferencesStorage:lastSync_2"), 1_696_204_800.0)

        let date3 = Date(year: 2023, month: 8, day: 1)
        let date4 = Date(year: 2023, month: 6, day: 2)

        subject.setLastSyncTime(date3, userId: "1")
        subject.setLastSyncTime(date4, userId: "2")

        XCTAssertEqual(subject.lastSyncTime(userId: "1"), date3)
        XCTAssertEqual(subject.lastSyncTime(userId: "2"), date4)
        XCTAssertEqual(userDefaults.double(forKey: "bwPreferencesStorage:lastSync_1"), 1_690_848_000.0)
        XCTAssertEqual(userDefaults.double(forKey: "bwPreferencesStorage:lastSync_2"), 1_685_664_000.0)
    }

    /// `masterPasswordHash(userId:)` returns `nil` if there isn't a previously stored value.
    func test_masterPasswordHash_isInitiallyNil() {
        XCTAssertNil(subject.masterPasswordHash(userId: "-1"))
    }

    /// `masterPasswordHash(userId:)` can be used to get the master password hash for a user.
    func test_masterPasswordHash_withValue() {
        subject.setMasterPasswordHash("1234", userId: "1")
        subject.setMasterPasswordHash("9876", userId: "2")

        XCTAssertEqual(subject.masterPasswordHash(userId: "1"), "1234")
        XCTAssertEqual(subject.masterPasswordHash(userId: "2"), "9876")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:keyHash_1"), "1234")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:keyHash_2"), "9876")

        subject.setMasterPasswordHash("abcd", userId: "1")
        subject.setMasterPasswordHash("zyxw", userId: "2")

        XCTAssertEqual(subject.masterPasswordHash(userId: "1"), "abcd")
        XCTAssertEqual(subject.masterPasswordHash(userId: "2"), "zyxw")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:keyHash_1"), "abcd")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:keyHash_2"), "zyxw")
    }

    /// `passwordGenerationOptions(userId:)` returns `nil` if there isn't a previously stored value.
    func test_passwordGenerationOptions_isInitiallyNil() {
        XCTAssertNil(subject.passwordGenerationOptions(userId: "-1"))
    }

    /// `passwordGenerationOptions(userId:)` can be used to get the password generation options for a user.
    func test_passwordGenerationOptions_withValue() {
        let options1 = PasswordGenerationOptions(length: 30, lowercase: true, type: .password, uppercase: true)
        let options2 = PasswordGenerationOptions(numWords: 5, type: .passphrase, wordSeparator: "-")

        subject.setPasswordGenerationOptions(options1, userId: "1")
        subject.setPasswordGenerationOptions(options2, userId: "2")

        try XCTAssertEqual(
            JSONDecoder().decode(
                PasswordGenerationOptions.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:passwordGenerationOptions_1")?
                        .data(using: .utf8)
                )
            ),
            options1
        )
        try XCTAssertEqual(
            JSONDecoder().decode(
                PasswordGenerationOptions.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:passwordGenerationOptions_2")?
                        .data(using: .utf8)
                )
            ),
            options2
        )

        XCTAssertEqual(subject.passwordGenerationOptions(userId: "1"), options1)
        XCTAssertEqual(subject.passwordGenerationOptions(userId: "2"), options2)
    }

    /// `preAuthEnvironmentUrls` returns `nil` if there isn't a previously stored value.
    func test_preAuthEnvironmentUrls_isInitiallyNil() {
        XCTAssertNil(subject.preAuthEnvironmentUrls)
    }

    /// `preAuthEnvironmentUrls` can be used to get and set the persisted value in user defaults.
    func test_preAuthEnvironmentUrls_withValue() {
        subject.preAuthEnvironmentUrls = .defaultUS
        XCTAssertEqual(subject.preAuthEnvironmentUrls, .defaultUS)
        try XCTAssertEqual(
            JSONDecoder().decode(
                EnvironmentUrlData.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:preAuthEnvironmentUrls")?
                        .data(using: .utf8)
                )
            ),
            .defaultUS
        )

        subject.preAuthEnvironmentUrls = .defaultEU
        XCTAssertEqual(subject.preAuthEnvironmentUrls, .defaultEU)
        try XCTAssertEqual(
            JSONDecoder().decode(
                EnvironmentUrlData.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:preAuthEnvironmentUrls")?
                        .data(using: .utf8)
                )
            ),
            .defaultEU
        )
    }

    /// `unsuccessfulUnlockAttempts` returns `0` if there isn't a previously stored value.
    func test_unsuccessfulUnlockAttempts_isInitially0() {
        XCTAssertEqual(0, subject.unsuccessfulUnlockAttempts(userId: "1"))
    }

    /// `unsuccessfulUnlockAttempts(userId:)`can be used to get the unsuccessful unlock attempts  for a user.
    func test_unsuccessfulUnlockAttempts_withValue() {
        subject.setUnsuccessfulUnlockAttempts(4, userId: "1")
        subject.setUnsuccessfulUnlockAttempts(1, userId: "3")

        XCTAssertEqual(subject.unsuccessfulUnlockAttempts(userId: "1"), 4)
        XCTAssertEqual(subject.unsuccessfulUnlockAttempts(userId: "3"), 1)

        XCTAssertEqual(4, userDefaults.integer(forKey: "bwPreferencesStorage:invalidUnlockAttempts_1"))
        XCTAssertEqual(1, userDefaults.integer(forKey: "bwPreferencesStorage:invalidUnlockAttempts_3"))
    }

    /// `usernameGenerationOptions(userId:)` returns `nil` if there isn't a previously stored value.
    func test_usernameGenerationOptions_isInitiallyNil() {
        XCTAssertNil(subject.usernameGenerationOptions(userId: "-1"))
    }

    /// `usernameGenerationOptions(userId:)` can be used to get the username generation options for a user.
    func test_usernameGenerationOptions_withValue() {
        let options1 = UsernameGenerationOptions(plusAddressedEmail: "user@bitwarden.com")
        let options2 = UsernameGenerationOptions(catchAllEmailDomain: "bitwarden.com")

        subject.setUsernameGenerationOptions(options1, userId: "1")
        subject.setUsernameGenerationOptions(options2, userId: "2")

        try XCTAssertEqual(
            JSONDecoder().decode(
                UsernameGenerationOptions.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:usernameGenerationOptions_1")?
                        .data(using: .utf8)
                )
            ),
            options1
        )
        try XCTAssertEqual(
            JSONDecoder().decode(
                UsernameGenerationOptions.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:usernameGenerationOptions_2")?
                        .data(using: .utf8)
                )
            ),
            options2
        )

        XCTAssertEqual(subject.usernameGenerationOptions(userId: "1"), options1)
        XCTAssertEqual(subject.usernameGenerationOptions(userId: "2"), options2)
    }

    /// `rememberedEmail` returns `nil` if there isn't a previously stored value.
    func test_rememberedEmail_isInitiallyNil() {
        XCTAssertNil(subject.rememberedEmail)
    }

    /// `rememberedEmail` can be used to get and set the persisted value in user defaults.
    func test_rememberedEmail_withValue() {
        subject.rememberedEmail = "email@example.com"
        XCTAssertEqual(subject.rememberedEmail, "email@example.com")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:rememberedEmail"), "email@example.com")

        subject.rememberedEmail = nil
        XCTAssertNil(subject.rememberedEmail)
        XCTAssertNil(userDefaults.string(forKey: "bwPreferencesStorage:rememberedEmail"))
    }

    /// `rememberedOrgIdentifier` returns `nil` if there isn't a previously stored value.
    func test_rememberedOrgIdentifier_isInitiallyNil() {
        XCTAssertNil(subject.rememberedOrgIdentifier)
    }

    /// `rememberedOrgIdentifier` can be used to get and set the persisted value in user defaults.
    func test_rememberedOrgIdentifier_withValue() {
        subject.rememberedOrgIdentifier = "OrgIdentifier9000"
        XCTAssertEqual(subject.rememberedOrgIdentifier, "OrgIdentifier9000")
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:rememberedOrgIdentifier"), "OrgIdentifier9000")

        subject.rememberedOrgIdentifier = nil
        XCTAssertNil(subject.rememberedOrgIdentifier)
        XCTAssertNil(userDefaults.string(forKey: "bwPreferencesStorage:rememberedOrgIdentifier"))
    }

    /// `state` returns `nil` if there isn't a previously stored value.
    func test_state_isInitiallyNil() {
        XCTAssertNil(subject.state)
    }

    /// `state` can be used to get and set the persisted value in user defaults.
    func test_state_withValue() throws {
        subject.state = State.fixture()
        XCTAssertEqual(subject.state, .fixture())
        XCTAssertEqual(
            try JSONDecoder().decode(
                State.self,
                from: Data(XCTUnwrap(userDefaults.string(forKey: "bwPreferencesStorage:state")).utf8)
            ),
            .fixture()
        )

        let stateMultipleAccounts = State.fixture(
            accounts: ["1": .fixture(), "2": .fixture()]
        )
        subject.state = stateMultipleAccounts
        XCTAssertEqual(subject.state, stateMultipleAccounts)
        XCTAssertEqual(
            try JSONDecoder().decode(
                State.self,
                from: Data(XCTUnwrap(userDefaults.string(forKey: "bwPreferencesStorage:state")).utf8)
            ),
            stateMultipleAccounts
        )

        subject.state = nil
        XCTAssertNil(subject.state)
        XCTAssertNil(userDefaults.data(forKey: "bwPreferencesStorage:state"))
    }

    /// `.timeoutAction(userId:)` returns the correct timeout action.
    func test_timeoutAction() throws {
        subject.setTimeoutAction(key: .logout, userId: "1")
        XCTAssertEqual(subject.timeoutAction(userId: "1"), 1)
        XCTAssertEqual(
            try JSONDecoder().decode(
                SessionTimeoutAction.self,
                from: Data(XCTUnwrap(userDefaults.string(forKey: "bwPreferencesStorage:vaultTimeoutAction_1")).utf8)
            ),
            .logout
        )
    }

    /// `.vaultTimeout(userId:)` returns the correct vault timeout value.
    func test_vaultTimeout() throws {
        subject.setVaultTimeout(key: 60, userId: "1")

        XCTAssertEqual(subject.vaultTimeout(userId: "1"), 60)
        XCTAssertEqual(userDefaults.double(forKey: "bwPreferencesStorage:vaultTimeout_1"), 60)
    }
}
