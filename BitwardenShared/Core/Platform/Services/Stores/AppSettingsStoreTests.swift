import BitwardenKit
import XCTest

@testable import BitwardenShared

// MARK: - AppSettingsStoreTests

// swiftlint:disable file_length

class AppSettingsStoreTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var subject: DefaultAppSettingsStore!
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

    /// `accountSetupAutofill(userId:)` returns `nil` if there isn't a previously stored value.
    func test_accountSetupAutofill_isInitiallyNil() {
        XCTAssertNil(subject.accountSetupAutofill(userId: "-1"))
    }

    /// `accountSetupAutofill(userId:)` can be used to get the user's progress for autofill setup.
    func test_accountSetupAutofill_withValue() {
        subject.setAccountSetupAutofill(.setUpLater, userId: "1")
        subject.setAccountSetupAutofill(.complete, userId: "2")

        XCTAssertEqual(subject.accountSetupAutofill(userId: "1"), .setUpLater)
        XCTAssertEqual(subject.accountSetupAutofill(userId: "2"), .complete)
        XCTAssertEqual(userDefaults.integer(forKey: "bwPreferencesStorage:accountSetupAutofill_1"), 1)
        XCTAssertEqual(userDefaults.integer(forKey: "bwPreferencesStorage:accountSetupAutofill_2"), 2)
    }

    /// `accountSetupImportLogins(userId:)` returns `nil` if there isn't a previously stored value.
    func test_accountSetupImportLogins_isInitiallyNil() {
        XCTAssertNil(subject.accountSetupImportLogins(userId: "-1"))
    }

    /// `accountSetupImportLogins(userId:)` can be used to get the user's progress for import logins setup.
    func test_accountSetupImportLogins_withValue() {
        subject.setAccountSetupImportLogins(.setUpLater, userId: "1")
        subject.setAccountSetupImportLogins(.complete, userId: "2")

        XCTAssertEqual(subject.accountSetupImportLogins(userId: "1"), .setUpLater)
        XCTAssertEqual(subject.accountSetupImportLogins(userId: "2"), .complete)
        XCTAssertEqual(userDefaults.integer(forKey: "bwPreferencesStorage:accountSetupImportLogins_1"), 1)
        XCTAssertEqual(userDefaults.integer(forKey: "bwPreferencesStorage:accountSetupImportLogins_2"), 2)
    }

    /// `accountSetupVaultUnlock(userId:)` returns `nil` if there isn't a previously stored value.
    func test_accountSetupVaultUnlock_isInitiallyFalse() {
        XCTAssertNil(subject.accountSetupVaultUnlock(userId: "-1"))
    }

    /// `accountSetupVaultUnlock(userId:)` can be used to get the user's progress for vault unlock setup.
    func test_accountSetupVaultUnlock_withValue() {
        subject.setAccountSetupVaultUnlock(.setUpLater, userId: "1")
        subject.setAccountSetupVaultUnlock(.complete, userId: "2")

        XCTAssertEqual(subject.accountSetupVaultUnlock(userId: "1"), .setUpLater)
        XCTAssertEqual(subject.accountSetupVaultUnlock(userId: "2"), .complete)
        XCTAssertEqual(userDefaults.integer(forKey: "bwPreferencesStorage:accountSetupVaultUnlock_1"), 1)
        XCTAssertEqual(userDefaults.integer(forKey: "bwPreferencesStorage:accountSetupVaultUnlock_2"), 2)
    }

    /// `addSitePromptShown` returns `false` if there isn't a previously stored value.
    func test_addSitePromptShown_isInitiallyFalse() {
        XCTAssertFalse(subject.addSitePromptShown)
    }

    /// `addSitePromptShown` can be used to get and set the persisted value in user defaults.
    func test_addSitePromptShown_withValue() {
        subject.addSitePromptShown = true
        XCTAssertTrue(subject.addSitePromptShown)
        XCTAssertTrue(userDefaults.bool(forKey: "bwPreferencesStorage:addSitePromptShown"))

        subject.addSitePromptShown = false
        XCTAssertFalse(subject.addSitePromptShown)
        XCTAssertFalse(userDefaults.bool(forKey: "bwPreferencesStorage:addSitePromptShown"))
    }

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

    /// `allowUniversalClipboard(userId:)` returns `false` if there isn't a previously stored value.
    func test_allowUniversalClipboard_isInitiallyFalse() {
        XCTAssertFalse(subject.allowUniversalClipboard(userId: "-1"))
    }

    /// `allowUniversalClipboard(userId:)` can be used to get the allow universal clipboard value for a user.
    func test_allowUniversalClipboard_withValue() {
        subject.setAllowUniversalClipboard(true, userId: "1")
        subject.setAllowUniversalClipboard(false, userId: "2")

        XCTAssertTrue(subject.allowUniversalClipboard(userId: "1"))
        XCTAssertFalse(subject.allowUniversalClipboard(userId: "2"))
        XCTAssertTrue(userDefaults.bool(forKey: "bwPreferencesStorage:allowUniversalClipboard_1"))
        XCTAssertFalse(userDefaults.bool(forKey: "bwPreferencesStorage:allowUniversalClipboard_w"))
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

    /// `appRehydrationState(userId:)` is initially `nil`
    func test_appRehydrationState_isInitiallyNil() {
        XCTAssertNil(subject.appRehydrationState(userId: "-1"))
    }

    /// `appRehydrationState(userId:)` is initially `nil`
    func test_appRehydrationState_withValue() {
        subject.setAppRehydrationState(
            AppRehydrationState(target: .viewCipher(cipherId: "1"), expirationTime: .now),
            userId: "1"
        )
        subject.setAppRehydrationState(
            AppRehydrationState(target: .viewCipher(cipherId: "2"), expirationTime: .now),
            userId: "2"
        )

        XCTAssertEqual(subject.appRehydrationState(userId: "1")?.target, .viewCipher(cipherId: "1"))
        XCTAssertEqual(subject.appRehydrationState(userId: "2")?.target, .viewCipher(cipherId: "2"))

        try XCTAssertEqual(
            JSONDecoder().decode(
                AppRehydrationState.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:appRehydrationState_1")?
                        .data(using: .utf8)
                )
            ).target,
            .viewCipher(cipherId: "1")
        )
        try XCTAssertEqual(
            JSONDecoder().decode(
                AppRehydrationState.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:appRehydrationState_2")?
                        .data(using: .utf8)
                )
            ).target,
            .viewCipher(cipherId: "2")
        )
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

    /// `cachedActiveUserId` returns `nil` if there isn't a cached active user.
    func test_cachedActiveUserId_isInitiallyNil() {
        XCTAssertNil(subject.cachedActiveUserId)
    }

    /// `cachedActiveUserId` returns the user ID of the last active user ID in the current process.
    func test_cachedActiveUserId_withValue() {
        subject.state = State(accounts: ["1": .fixture()], activeUserId: "1")
        XCTAssertEqual(subject.cachedActiveUserId, "1")

        subject.state = State(
            accounts: [
                "1": .fixture(profile: .fixture(userId: "1")),
                "2": .fixture(profile: .fixture(userId: "2")),
            ],
            activeUserId: "2"
        )
        XCTAssertEqual(subject.cachedActiveUserId, "2")
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

    /// `.encryptedPin(_:userId:)` can be used to get the user's encrypted pin.
    func test_encryptedPin() {
        let userId = Account.fixture().profile.userId
        subject.setEncryptedPin("123", userId: userId)
        let pin = subject.encryptedPin(userId: userId)
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:protectedPin_1"), pin)
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

    /// `events(userId:)` can be used to get the events for a user.
    func test_events() {
        let events = [
            EventData(type: .cipherAttachmentCreated, cipherId: "1", date: .now),
            EventData(type: .userUpdated2fa, cipherId: nil, date: .now),
        ]
        subject.setEvents(events, userId: "0")
        XCTAssertEqual(subject.events(userId: "0"), events)
    }

    /// `events(userId:)` returns an empty array if there are no events for a user.
    func test_events_empty() {
        XCTAssertEqual(subject.events(userId: "1"), [])
    }

    /// `overrideDebugFeatureFlag(name:value:)` and `debugFeatureFlag(name:)` work as expected with correct values.
    func test_featureFlags() {
        let featureFlags: [FeatureFlag] = [.testFeatureFlag]

        for flag in featureFlags {
            subject.overrideDebugFeatureFlag(name: flag.rawValue, value: true)
        }

        XCTAssertTrue(try XCTUnwrap(subject.debugFeatureFlag(name: FeatureFlag.testFeatureFlag.rawValue)))
    }

    /// `featureFlag(name:)` returns `nil` if not found.
    func test_featureFlags_nilWhenNotPresent() {
        XCTAssertNil(subject.debugFeatureFlag(name: ""))
    }

    /// `flightRecorderData` returns `nil` if there isn't any previously stored flight recorder data.
    func test_flightRecorderData_isInitiallyNil() {
        XCTAssertNil(subject.flightRecorderData)
    }

    /// `flightRecorderData` can be used to get and set the flight recorder data.
    func test_flightRecorderData_withValue() throws {
        let flightRecorderData = FlightRecorderData(
            activeLog: FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now),
            inactiveLogs: []
        )
        subject.flightRecorderData = flightRecorderData

        let data = try XCTUnwrap(
            userDefaults.string(forKey: "bwPreferencesStorage:flightRecorderData")?
                .data(using: .utf8)
        )
        let decodedData = try JSONDecoder().decode(FlightRecorderData.self, from: data)
        XCTAssertEqual(decodedData, flightRecorderData)

        subject.flightRecorderData = nil
        XCTAssertNil(userDefaults.string(forKey: "bwPreferencesStorage:flightRecorderData"))
    }

    /// `hasPerformedSyncAfterLogin(userId:)` returns `false` if there isn't a previously stored value.
    func test_hasPerformedSyncAfterLogin_initialValue() {
        XCTAssertFalse(subject.hasPerformedSyncAfterLogin(userId: "0"))
    }

    /// `hasPerformedSyncAfterLogin(userId:)` returns `false` or `true` depending what is saved in user defaults.
    func test_hasPerformedSyncAfterLogin_withValue() {
        subject.setHasPerformedSyncAfterLogin(false, userId: "1")
        subject.setHasPerformedSyncAfterLogin(true, userId: "2")

        XCTAssertFalse(subject.hasPerformedSyncAfterLogin(userId: "1"))
        XCTAssertTrue(subject.hasPerformedSyncAfterLogin(userId: "2"))
    }

    /// `isBiometricAuthenticationEnabled` returns false if there is no previous value.
    func test_isBiometricAuthenticationEnabled_isInitiallyFalse() {
        XCTAssertFalse(subject.isBiometricAuthenticationEnabled(userId: "-1"))
    }

    /// `introCarouselShown` returns `false` if there isn't a previously stored value.
    func test_introCarouselShown_isInitiallyFalse() {
        XCTAssertFalse(subject.introCarouselShown)
    }

    /// `introCarouselShown` can be used to get and set the persisted value in user defaults.
    func test_introCarouselShown_withValue() {
        subject.introCarouselShown = true
        XCTAssertTrue(subject.introCarouselShown)
        XCTAssertTrue(userDefaults.bool(forKey: "bwPreferencesStorage:introCarouselShown"))

        subject.introCarouselShown = false
        XCTAssertFalse(subject.introCarouselShown)
        XCTAssertFalse(userDefaults.bool(forKey: "bwPreferencesStorage:introCarouselShown"))
    }

    /// `isBiometricAuthenticationEnabled` can be used to get the biometric unlock preference for a user.
    func test_isBiometricAuthenticationEnabled_withValue() {
        subject.setBiometricAuthenticationEnabled(false, for: "0")
        subject.setBiometricAuthenticationEnabled(true, for: "1")

        XCTAssertFalse(subject.isBiometricAuthenticationEnabled(userId: "0"))
        XCTAssertTrue(subject.isBiometricAuthenticationEnabled(userId: "1"))

        subject.setBiometricAuthenticationEnabled(true, for: "0")
        subject.setBiometricAuthenticationEnabled(false, for: "1")

        XCTAssertTrue(subject.isBiometricAuthenticationEnabled(userId: "0"))
        XCTAssertFalse(subject.isBiometricAuthenticationEnabled(userId: "1"))
    }

    /// `learnNewLoginActionCardStatus` returns `.incomplete` if there isn't a previously stored value.
    func test_learnNewLoginActionCardStatus_isInitiallyIncomplete() {
        XCTAssertEqual(subject.learnNewLoginActionCardStatus, .incomplete)
    }

    /// `learnNewLoginActionCardStatus`  can be used to get and set the persisted value in user defaults.
    func test_learnNewLoginActionCardStatus_withValues() {
        subject.learnNewLoginActionCardStatus = .complete
        XCTAssertEqual(subject.learnNewLoginActionCardStatus, .complete)

        try XCTAssertEqual(
            JSONDecoder().decode(
                AccountSetupProgress.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:learnNewLoginActionCardStatus")?
                        .data(using: .utf8)
                )
            ),
            AccountSetupProgress.complete
        )
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

    /// `lastActiveTime(userId:)` returns `nil` if there isn't a previously stored value.
    func test_lastActiveTime_isInitiallyNil() {
        XCTAssertNil(subject.lastActiveTime(userId: "-1"))
    }

    /// `lastActiveTime(userId:)` can be used to get the last active time for a user.
    func test_lastActiveTime_withValue() {
        let date1 = Date(year: 2023, month: 12, day: 1)
        let date2 = Date(year: 2023, month: 10, day: 2)

        subject.setLastActiveTime(date1, userId: "1")
        subject.setLastActiveTime(date2, userId: "2")

        XCTAssertEqual(subject.lastActiveTime(userId: "1"), date1)
        XCTAssertEqual(subject.lastActiveTime(userId: "2"), date2)
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

    /// `learnGeneratorActionCardStatus` returns `.incomplete` if there isn't a previously stored value.
    func test_learnGeneratorActionCardStatus_isInitiallyIncomplete() {
        XCTAssertEqual(subject.learnGeneratorActionCardStatus, .incomplete)
    }

    /// `learnGeneratorActionCardStatus`  can be used to get and set the persisted value in user defaults.
    func test_learnGeneratorActionCardStatus_withValues() {
        subject.learnGeneratorActionCardStatus = .complete
        XCTAssertEqual(subject.learnGeneratorActionCardStatus, .complete)

        try XCTAssertEqual(
            JSONDecoder().decode(
                AccountSetupProgress.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:learnGeneratorActionCardStatus")?
                        .data(using: .utf8)
                )
            ),
            AccountSetupProgress.complete
        )
    }

    /// `loginRequest` returns `nil` if there isn't a previously stored value.
    func test_loginRequest_isInitiallyNil() {
        XCTAssertNil(subject.loginRequest)
    }

    /// `loginRequest` can be used to get and set the login request data.
    func test_loginRequest_withValue() throws {
        let loginRequest = LoginRequestNotification(id: "1", userId: "10")

        subject.loginRequest = loginRequest

        XCTAssertEqual(subject.loginRequest, loginRequest)
        try XCTAssertEqual(
            JSONDecoder().decode(
                LoginRequestNotification.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:passwordlessLoginNotificationKey")?
                        .data(using: .utf8)
                )
            ),
            loginRequest
        )
    }

    /// `manuallyLockedAccount(userId:)` returns `false` if there isn't a previously stored value.
    func test_manuallyLockedAccount_isInitiallyFalse() {
        XCTAssertFalse(subject.manuallyLockedAccount(userId: "-1"))
    }

    /// `manuallyLockedAccount(userId:)` can be used to get whether the account has been manually locked.
    func test_manuallyLockedAccount_withValue() {
        subject.setManuallyLockedAccount(false, userId: "1")
        subject.setManuallyLockedAccount(true, userId: "2")

        XCTAssertFalse(subject.manuallyLockedAccount(userId: "1"))
        XCTAssertTrue(subject.manuallyLockedAccount(userId: "2"))
        XCTAssertFalse(userDefaults.bool(forKey: "bwPreferencesStorage:manuallyLockedAccount_1"))
        XCTAssertTrue(userDefaults.bool(forKey: "bwPreferencesStorage:manuallyLockedAccount_2"))

        subject.setManuallyLockedAccount(true, userId: "1")
        subject.setManuallyLockedAccount(false, userId: "2")

        XCTAssertTrue(subject.manuallyLockedAccount(userId: "1"))
        XCTAssertFalse(subject.manuallyLockedAccount(userId: "2"))
        XCTAssertTrue(userDefaults.bool(forKey: "bwPreferencesStorage:manuallyLockedAccount_1"))
        XCTAssertFalse(userDefaults.bool(forKey: "bwPreferencesStorage:manuallyLockedAccount_2"))
    }

    /// `migrationVersion` returns `0` if there isn't a previously stored value.
    func test_migrationVersion_isInitiallyZero() {
        XCTAssertEqual(subject.migrationVersion, 0)
    }

    /// `migrationVersion` can be used to get and set the migration version.
    func test_migrationVersion_withValue() throws {
        subject.migrationVersion = 1
        XCTAssertEqual(userDefaults.integer(forKey: "bwPreferencesStorage:migrationVersion"), 1)
        XCTAssertEqual(subject.migrationVersion, 1)

        subject.migrationVersion = 2
        XCTAssertEqual(userDefaults.integer(forKey: "bwPreferencesStorage:migrationVersion"), 2)
        XCTAssertEqual(subject.migrationVersion, 2)
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

    /// `notificationsLastRegistrationDate(userId:)` returns `nil` if there isn't a previously stored value.
    func test_notificationsLastRegistrationDate_isInitiallyNil() {
        XCTAssertNil(subject.notificationsLastRegistrationDate(userId: "-1"))
    }

    /// `notificationsLastRegistrationDate(userId:)` can be used to get the last notifications registration date for a
    /// user.
    func test_notificationsLastRegistrationDate_withValue() {
        let date1 = Date(year: 2023, month: 12, day: 1)
        let date2 = Date(year: 2023, month: 10, day: 2)

        subject.setNotificationsLastRegistrationDate(date1, userId: "1")
        subject.setNotificationsLastRegistrationDate(date2, userId: "2")

        XCTAssertEqual(subject.notificationsLastRegistrationDate(userId: "1"), date1)
        XCTAssertEqual(subject.notificationsLastRegistrationDate(userId: "2"), date2)
        XCTAssertEqual(userDefaults.double(forKey: "bwPreferencesStorage:pushLastRegistrationDate_1"), 1_701_388_800.0)
        XCTAssertEqual(userDefaults.double(forKey: "bwPreferencesStorage:pushLastRegistrationDate_2"), 1_696_204_800.0)
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

    /// `pendingAppIntentActions`is initially `nil`.
    func test_pendingAppIntentActions_isInitiallyNil() {
        XCTAssertNil(subject.pendingAppIntentActions)
    }

    /// `pendingAppIntentActions` can be used to get and set the persisted pending app intent actions in user defaults.
    func test_pendingAppIntentActions_withValue() throws {
        subject.pendingAppIntentActions = [.lockAll]
        XCTAssertEqual(subject.pendingAppIntentActions, [.lockAll])
        try XCTAssertEqual(
            JSONDecoder().decode(
                [PendingAppIntentAction].self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:pendingAppIntentActions")?
                        .data(using: .utf8)
                )
            ),
            [.lockAll]
        )

        subject.pendingAppIntentActions = nil
        XCTAssertNil(subject.pendingAppIntentActions)
        XCTAssertNil(userDefaults.string(forKey: "bwPreferencesStorage:pendingAppIntentActions"))
    }

    /// `.pinProtectedUserKey(userId:)` can be used to get the pin protected user key for a user.
    func test_pinProtectedUserKey() {
        let userId = Account.fixture().profile.userId
        subject.setPinProtectedUserKey(key: "123", userId: userId)
        let pin = subject.pinProtectedUserKey(userId: userId)
        XCTAssertEqual(userDefaults.string(forKey: "bwPreferencesStorage:pinKeyEncryptedUserKey_1"), pin)
    }

    /// `preAuthEnvironmentURLs` returns `nil` if there isn't a previously stored value.
    func test_preAuthEnvironmentURLs_isInitiallyNil() {
        XCTAssertNil(subject.preAuthEnvironmentURLs)
    }

    /// `preAuthEnvironmentURLs` can be used to get and set the persisted value in user defaults.
    func test_preAuthEnvironmentURLs_withValue() {
        subject.preAuthEnvironmentURLs = .defaultUS
        XCTAssertEqual(subject.preAuthEnvironmentURLs, .defaultUS)
        try XCTAssertEqual(
            JSONDecoder().decode(
                EnvironmentURLData.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:preAuthEnvironmentUrls")?
                        .data(using: .utf8)
                )
            ),
            .defaultUS
        )

        subject.preAuthEnvironmentURLs = .defaultEU
        XCTAssertEqual(subject.preAuthEnvironmentURLs, .defaultEU)
        try XCTAssertEqual(
            JSONDecoder().decode(
                EnvironmentURLData.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:preAuthEnvironmentUrls")?
                        .data(using: .utf8)
                )
            ),
            .defaultEU
        )
    }

    /// `accountCreationEnvironmentURLs` returns `nil` if there isn't a previously stored value.
    func test_accountCreationEnvironmentURLs_isInitiallyNil() {
        XCTAssertNil(subject.accountCreationEnvironmentURLs(email: "example@email.com"))
    }

    /// `accountCreationEnvironmentURLs` can be used to get and set the persisted value in user defaults.
    func test_accountCreationEnvironmentURLs_withValue() {
        let email = "example@email.com"
        subject.setAccountCreationEnvironmentURLs(environmentURLData: .defaultUS, email: email)
        XCTAssertEqual(subject.accountCreationEnvironmentURLs(email: email), .defaultUS)
        try XCTAssertEqual(
            JSONDecoder().decode(
                EnvironmentURLData.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:accountCreationEnvironmentUrls_\(email)")?
                        .data(using: .utf8)
                )
            ),
            .defaultUS
        )

        subject.setAccountCreationEnvironmentURLs(environmentURLData: .defaultEU, email: email)
        XCTAssertEqual(subject.accountCreationEnvironmentURLs(email: email), .defaultEU)
        try XCTAssertEqual(
            JSONDecoder().decode(
                EnvironmentURLData.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:accountCreationEnvironmentUrls_\(email)")?
                        .data(using: .utf8)
                )
            ),
            .defaultEU
        )
    }

    /// `preAuthServerConfig` is initially `nil`
    func test_preAuthServerConfig_isInitiallyNil() {
        XCTAssertNil(subject.preAuthServerConfig)
    }

    /// `preAuthServerConfig` can be used to get and set the persisted value in user defaults.
    func test_preAuthServerConfig_withValue() {
        let config = ServerConfig(
            date: Date(timeIntervalSince1970: 100),
            responseModel: ConfigResponseModel(
                environment: EnvironmentServerConfigResponseModel(
                    api: "https://vault.bitwarden.com",
                    cloudRegion: "US",
                    identity: "https://vault.bitwarden.com",
                    notifications: "https://vault.bitwarden.com",
                    sso: "https://vault.bitwarden.com",
                    vault: "https://vault.bitwarden.com"
                ),
                featureStates: ["feature": .bool(true)],
                gitHash: "hash",
                server: ThirdPartyConfigResponseModel(
                    name: "Name",
                    url: "Url"
                ),
                version: "version"
            )
        )
        subject.preAuthServerConfig = config

        XCTAssertEqual(subject.preAuthServerConfig, config)
        try XCTAssertEqual(
            JSONDecoder().decode(
                ServerConfig.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:preAuthServerConfig")?
                        .data(using: .utf8)
                )
            ),
            config
        )
    }

    /// `serverConfig(:)` is initially `nil`
    func test_serverConfig_isInitiallyNil() {
        XCTAssertNil(subject.serverConfig(userId: "1"))
    }

    /// `serverConfig(:)` can be used to get and set the persisted value in user defaults.
    func test_serverConfig_withValue() {
        let config = ServerConfig(
            date: Date(timeIntervalSince1970: 100),
            responseModel: ConfigResponseModel(
                environment: EnvironmentServerConfigResponseModel(
                    api: "https://vault.bitwarden.com",
                    cloudRegion: "US",
                    identity: "https://vault.bitwarden.com",
                    notifications: "https://vault.bitwarden.com",
                    sso: "https://vault.bitwarden.com",
                    vault: "https://vault.bitwarden.com"
                ),
                featureStates: ["feature": .bool(true)],
                gitHash: "hash",
                server: ThirdPartyConfigResponseModel(
                    name: "Name",
                    url: "Url"
                ),
                version: "version"
            )
        )
        subject.setServerConfig(config, userId: "1")

        XCTAssertEqual(subject.serverConfig(userId: "1"), config)
        try XCTAssertEqual(
            JSONDecoder().decode(
                ServerConfig.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:serverConfig_1")?
                        .data(using: .utf8)
                )
            ),
            config
        )
    }

    /// `setHasPerformedSyncAfterLogin(hasBeenPerformed:, userId:)` can be used to
    /// set the has performed sync after login.
    func test_setHasPerformedSyncAfterLogin() {
        subject.setHasPerformedSyncAfterLogin(true, userId: "1")
        XCTAssertTrue(userDefaults.bool(forKey: "bwPreferencesStorage:hasPerformedSyncAfterLogin_1"))

        subject.setHasPerformedSyncAfterLogin(false, userId: "1")
        XCTAssertFalse(userDefaults.bool(forKey: "bwPreferencesStorage:hasPerformedSyncAfterLogin_1"))

        subject.setHasPerformedSyncAfterLogin(nil, userId: "1")
        XCTAssertFalse(userDefaults.bool(forKey: "bwPreferencesStorage:hasPerformedSyncAfterLogin_1"))
    }

    /// `siriAndShortcutsAccess(userId:)` returns false if there isn't a previously stored value.
    func test_siriAndShortcutsAccess_isInitiallyFalse() {
        XCTAssertFalse(subject.siriAndShortcutsAccess(userId: "0"))
    }

    /// `siriAndShortcutsAccess(userId:)` can be used to get the Siri & Shortcuts access value for a user.
    func test_siriAndShortcutsAccess_withValue() {
        subject.setSiriAndShortcutsAccess(true, userId: "1")
        subject.setSiriAndShortcutsAccess(false, userId: "2")

        XCTAssertTrue(subject.siriAndShortcutsAccess(userId: "1"))
        XCTAssertFalse(subject.siriAndShortcutsAccess(userId: "2"))
        XCTAssertTrue(userDefaults.bool(forKey: "bwPreferencesStorage:siriAndShortcutsAccess_1"))
        XCTAssertFalse(userDefaults.bool(forKey: "bwPreferencesStorage:siriAndShortcutsAccess_2"))
    }

    /// `syncToAuthenticator(userId:)` returns false if there isn't a previously stored value.
    func test_syncToAuthenticator_isInitiallyFalse() {
        XCTAssertFalse(subject.syncToAuthenticator(userId: "0"))
    }

    /// `syncToAuthenticator(userId:)` can be used to get the sync to authenticator value for a user.
    func test_syncToAuthenticator_withValue() {
        subject.setSyncToAuthenticator(true, userId: "1")
        subject.setSyncToAuthenticator(false, userId: "2")

        XCTAssertTrue(subject.syncToAuthenticator(userId: "1"))
        XCTAssertFalse(subject.syncToAuthenticator(userId: "2"))
        XCTAssertTrue(userDefaults.bool(forKey: "bwPreferencesStorage:shouldSyncToAuthenticator_1"))
        XCTAssertFalse(userDefaults.bool(forKey: "bwPreferencesStorage:shouldSyncToAuthenticator_2"))
    }

    /// `twoFactorToken(email:)` returns `nil` if there isn't a previously stored value.
    func test_twoFactorToken_isInitiallyNil() {
        XCTAssertNil(subject.twoFactorToken(email: "anything@email.com"))
    }

    /// `twoFactorToken(email:)` can be used to get and set the persisted value in user defaults.
    func test_twoFactorToken_withValue() {
        subject.setTwoFactorToken("tests_that_work", email: "lucky@gmail.com")
        subject.setTwoFactorToken("tests_are_great", email: "happy@gmail.com")

        XCTAssertEqual(subject.twoFactorToken(email: "lucky@gmail.com"), "tests_that_work")
        XCTAssertEqual(subject.twoFactorToken(email: "happy@gmail.com"), "tests_are_great")

        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:twoFactorToken_lucky@gmail.com"),
            "tests_that_work"
        )
        XCTAssertEqual(
            userDefaults.string(forKey: "bwPreferencesStorage:twoFactorToken_happy@gmail.com"),
            "tests_are_great"
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

    /// `reviewPromptShownForVersion` returns `nil` if there isn't a previously stored value.
    func test_reviewPromptShownForVersion_isInitiallyNil() {
        XCTAssertNil(subject.reviewPromptData?.reviewPromptShownForVersion)
    }

    /// `reviewPromptData` returns `nil` if there isn't a previously stored value.
    func test_reviewPromptData_isInitiallyNil() {
        XCTAssertNil(subject.reviewPromptData)
    }

    /// `reviewPromptData` can be used to get and set the persisted value in user defaults.
    func test_reviewPromptData_withValue() {
        let reviewPromptData = ReviewPromptData(
            reviewPromptShownForVersion: "1.2.1",
            userActions: [
                UserActionItem(
                    userAction: .addedNewItem,
                    count: 3
                ),
            ]
        )
        subject.reviewPromptData = reviewPromptData
        XCTAssertEqual(subject.reviewPromptData, reviewPromptData)

        try XCTAssertEqual(
            JSONDecoder().decode(
                ReviewPromptData.self,
                from: XCTUnwrap(
                    userDefaults
                        .string(forKey: "bwPreferencesStorage:reviewPromptData")?
                        .data(using: .utf8)
                )
            ),
            reviewPromptData
        )
    }

    /// `usesKeyConnector(userId:)` returns `false` if there isn't a previously stored value.
    func test_usesKeyConnector_isInitiallyNil() {
        XCTAssertFalse(subject.usesKeyConnector(userId: "-1"))
    }

    /// `usesKeyConnector(userId:)` can be used to get whether the user uses key connector.
    func test_usesKeyConnector_withValue() {
        subject.setUsesKeyConnector(true, userId: "1")
        subject.setUsesKeyConnector(false, userId: "2")

        XCTAssertTrue(subject.usesKeyConnector(userId: "1"))
        XCTAssertFalse(subject.usesKeyConnector(userId: "2"))
        XCTAssertTrue(userDefaults.bool(forKey: "bwPreferencesStorage:usesKeyConnector_1"))
        XCTAssertFalse(userDefaults.bool(forKey: "bwPreferencesStorage:usesKeyConnector_2"))
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
        subject.setVaultTimeout(minutes: 60, userId: "1")

        XCTAssertEqual(subject.vaultTimeout(userId: "1"), 60)
        XCTAssertEqual(userDefaults.double(forKey: "bwPreferencesStorage:vaultTimeout_1"), 60)
    }
}
