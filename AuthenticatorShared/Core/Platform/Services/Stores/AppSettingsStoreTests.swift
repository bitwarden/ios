import BitwardenKit
import XCTest

@testable import AuthenticatorShared

// MARK: - AppSettingsStoreTests

class AppSettingsStoreTests: BitwardenTestCase {
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

    /// `defaultSaveOption` returns `.none` if there isn't a previously stored value or if a previously
    /// stored value is not a valid option
    func test_defaultSaveOption_isInitiallyNone() {
        XCTAssertEqual(subject.defaultSaveOption, .none)

        userDefaults.set("An invalid value", forKey: "bwaPreferencesStorage:defaultSaveOption")
        XCTAssertEqual(subject.defaultSaveOption, .none)
    }

    /// `defaultSaveOption` can be used to get and set the default save option.
    func test_defaultSaveOption_withValue() {
        subject.defaultSaveOption = .saveToBitwarden
        XCTAssertEqual(subject.defaultSaveOption, .saveToBitwarden)
        XCTAssertEqual(userDefaults.string(forKey: "bwaPreferencesStorage:defaultSaveOption"), "saveToBitwarden")

        subject.defaultSaveOption = .saveHere
        XCTAssertEqual(subject.defaultSaveOption, .saveHere)
        XCTAssertEqual(userDefaults.string(forKey: "bwaPreferencesStorage:defaultSaveOption"), "saveHere")

        subject.defaultSaveOption = .none
        XCTAssertEqual(subject.defaultSaveOption, .none)
        XCTAssertEqual(userDefaults.string(forKey: "bwaPreferencesStorage:defaultSaveOption"), "none")
    }

    /// `flightRecorderData` returns `nil` if there isn't any previously stored flight recorder data.
    func test_flightRecorderData_isInitiallyNil() {
        XCTAssertNil(subject.flightRecorderData)
    }

    /// `flightRecorderData` can be used to get and set the flight recorder data.
    func test_flightRecorderData_withValue() throws {
        let flightRecorderData = FlightRecorderData(
            activeLog: FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now),
            inactiveLogs: [],
        )
        subject.flightRecorderData = flightRecorderData

        let data = try XCTUnwrap(
            userDefaults.string(forKey: "bwaPreferencesStorage:flightRecorderData")?
                .data(using: .utf8),
        )
        let decodedData = try JSONDecoder().decode(FlightRecorderData.self, from: data)
        XCTAssertEqual(decodedData, flightRecorderData)

        subject.flightRecorderData = nil
        XCTAssertNil(userDefaults.string(forKey: "bwaPreferencesStorage:flightRecorderData"))
    }

    /// `hasSeenDefaultSaveOptionPrompt` returns `false` if there isn't a 'defaultSaveOption` value stored, and `true`
    /// when there is a value stored.
    func test_hasSeenDefaultSaveOptionPrompt() {
        XCTAssertFalse(subject.hasSeenDefaultSaveOptionPrompt)

        subject.defaultSaveOption = .none
        XCTAssertTrue(subject.hasSeenDefaultSaveOptionPrompt)
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

    /// `hasSyncedAccount(name:)` can be used to get and set if the user has synced previously with a given account.
    /// Account names should be hashed so as to not appear in plaintext.
    func test_hasSyncedAccount_withValue() {
        let accountName = "test@example.com | vault.bitwarden.com"
        subject.setHasSyncedAccount(name: accountName)
        XCTAssertTrue(subject.hasSyncedAccount(name: accountName))

        // Doesn't store the account as plain text:
        XCTAssertFalse(userDefaults.bool(forKey: "bwaPreferencesStorage:hasSyncedAccount_\(accountName)"))

        // Stores with the hashed value:
        XCTAssertTrue(userDefaults.bool(
            forKey: "bwaPreferencesStorage:hasSyncedAccount_\(accountName.hexSHA256Hash)",
        ))

        // A new account that we've not synced before defaults to `false`
        XCTAssertFalse(subject.hasSyncedAccount(name: "New Account"))
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

    /// `.vaultTimeout(userId:)` returns the correct vault timeout value.
    func test_vaultTimeout() throws {
        subject.setVaultTimeout(minutes: 60, userId: "1")

        XCTAssertEqual(subject.vaultTimeout(userId: "1"), 60)
        XCTAssertEqual(userDefaults.double(forKey: "bwaPreferencesStorage:vaultTimeout_1"), 60)
    }
}
