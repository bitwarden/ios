import XCTest

@testable import AuthenticatorShared

// MARK: - AppSettingsStoreTests

class AppSettingsStoreTests: AuthenticatorTestCase {
    // MARK: Properties

    var subject: AppSettingsStore!
    var userDefaults: UserDefaults!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        userDefaults = UserDefaults(suiteName: "AppSettingsStoreTests")

        userDefaults.dictionaryRepresentation()
            .keys
            .filter { $0.hasPrefix("bwaPreferencesStorage:") }
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
        XCTAssertEqual(userDefaults.string(forKey: "bwaPreferencesStorage:appId"), "📱")

        subject.appId = "☎️"
        XCTAssertEqual(subject.appId, "☎️")
        XCTAssertEqual(userDefaults.string(forKey: "bwaPreferencesStorage:appId"), "☎️")

        subject.appId = nil
        XCTAssertNil(subject.appId)
        XCTAssertNil(userDefaults.string(forKey: "bwaPreferencesStorage:appId"))
    }

    /// `appLocale`is initially `nil`.
    func test_appLocale_isInitiallyNil() {
        XCTAssertNil(subject.appLocale)
    }

    /// `appLocale` can be used to get and set the persisted value in user defaults.
    func test_appLocale_withValue() {
        subject.appLocale = "th"
        XCTAssertEqual(subject.appLocale, "th")
        XCTAssertEqual(userDefaults.string(forKey: "bwaPreferencesStorage:appLocale"), "th")

        subject.appLocale = nil
        XCTAssertNil(subject.appLocale)
        XCTAssertNil(userDefaults.string(forKey: "bwaPreferencesStorage:appLocale"))
    }

    /// `appTheme` returns `nil` if there isn't a previously stored value.
    func test_appTheme_isInitiallyNil() {
        XCTAssertNil(subject.appTheme)
    }

    /// `appTheme` can be used to get and set the persisted value in user defaults.
    func test_appTheme_withValue() {
        subject.appTheme = "light"
        XCTAssertEqual(subject.appTheme, "light")
        XCTAssertEqual(userDefaults.string(forKey: "bwaPreferencesStorage:theme"), "light")

        subject.appTheme = nil
        XCTAssertNil(subject.appTheme)
        XCTAssertNil(userDefaults.string(forKey: "bwaPreferencesStorage:theme"))
    }

    /// `biometricIntegrityState` returns nil if there is no previous value.
    func test_biometricIntegrityState_isInitiallyNil() {
        XCTAssertNil(subject.biometricIntegrityState(userId: "-1"))
    }

    /// `biometricIntegrityState` can be used to get and set the persisted value in user defaults.
    func test_biometricIntegrityState_withValue() {
        subject.setBiometricIntegrityState("state1", userId: "0")
        subject.setBiometricIntegrityState("state2", userId: "1")

        XCTAssertEqual("state1", subject.biometricIntegrityState(userId: "0"))
        XCTAssertEqual("state2", subject.biometricIntegrityState(userId: "1"))

        subject.setBiometricIntegrityState("state3", userId: "0")
        subject.setBiometricIntegrityState("state4", userId: "1")

        XCTAssertEqual("state3", subject.biometricIntegrityState(userId: "0"))
        XCTAssertEqual("state4", subject.biometricIntegrityState(userId: "1"))
    }

    /// `cardClosedState` returns `false` if there isn't a previously stored value.
    func test_cardClosedState_isInitiallyFalse() {
        XCTAssertFalse(subject.cardClosedState(card: .passwordManagerDownload))
        XCTAssertFalse(subject.cardClosedState(card: .passwordManagerSync))
    }

    /// `cardClosedState` can be used to get and set the persisted value in user defaults.
    func test_cardClosedState_withValue() {
        subject.setCardClosedState(card: .passwordManagerDownload)
        XCTAssertTrue(subject.cardClosedState(card: .passwordManagerDownload))
        XCTAssertTrue(userDefaults.bool(forKey: "bwaPreferencesStorage:cardClosedState_passwordManagerDownload"))

        subject.setCardClosedState(card: .passwordManagerSync)
        XCTAssertTrue(subject.cardClosedState(card: .passwordManagerSync))
        XCTAssertTrue(userDefaults.bool(forKey: "bwaPreferencesStorage:cardClosedState_passwordManagerSync"))
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
        XCTAssertEqual(userDefaults.integer(forKey: "bwaPreferencesStorage:clearClipboard_1"), 10)
        XCTAssertEqual(userDefaults.integer(forKey: "bwaPreferencesStorage:clearClipboard_2"), -1)
    }

    /// `disableWebIcons` returns `false` if there isn't a previously stored value.
    func test_disableWebIcons_isInitiallyFalse() {
        XCTAssertFalse(subject.disableWebIcons)
    }

    /// `disableWebIcons` can be used to get and set the persisted value in user defaults.
    func test_disableWebIcons_withValue() {
        subject.disableWebIcons = true
        XCTAssertTrue(subject.disableWebIcons)
        XCTAssertTrue(userDefaults.bool(forKey: "bwaPreferencesStorage:disableFavicon"))

        subject.disableWebIcons = false
        XCTAssertFalse(subject.disableWebIcons)
        XCTAssertFalse(userDefaults.bool(forKey: "bwaPreferencesStorage:disableFavicon"))
    }

    /// `isBiometricAuthenticationEnabled` returns false if there is no previous value.
    func test_isBiometricAuthenticationEnabled_isInitiallyFalse() {
        XCTAssertFalse(subject.isBiometricAuthenticationEnabled(userId: "-1"))
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

    /// `migrationVersion` returns `0` if there isn't a previously stored value.
    func test_migrationVersion_isInitiallyZero() {
        XCTAssertEqual(subject.migrationVersion, 0)
    }

    /// `migrationVersion` can be used to get and set the migration version.
    func test_migrationVersion_withValue() throws {
        subject.migrationVersion = 1
        XCTAssertEqual(userDefaults.integer(forKey: "bwaPreferencesStorage:migrationVersion"), 1)
        XCTAssertEqual(subject.migrationVersion, 1)

        subject.migrationVersion = 2
        XCTAssertEqual(userDefaults.integer(forKey: "bwaPreferencesStorage:migrationVersion"), 2)
        XCTAssertEqual(subject.migrationVersion, 2)
    }
}
