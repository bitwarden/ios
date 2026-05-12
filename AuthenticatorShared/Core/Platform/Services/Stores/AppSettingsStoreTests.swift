import BitwardenKit
import Foundation
import Testing

@testable import AuthenticatorShared

// MARK: - AppSettingsStoreTests

struct AppSettingsStoreTests {
    // MARK: Properties

    let subject: DefaultAppSettingsStore
    let userDefaults: UserDefaults

    // MARK: Setup

    init() {
        // Enables parallel testing while using User Defaults.
        let defaults = UserDefaults(suiteName: "AppSettingsStoreTests-\(UUID().uuidString)")!
        userDefaults = defaults
        subject = DefaultAppSettingsStore(userDefaults: defaults)
    }

    // MARK: Tests

    /// `appID` returns `nil` if there isn't a previously stored value.
    @Test
    func appID_isInitiallyNil() {
        #expect(subject.appID == nil)
    }

    /// `appID` can be used to get and set the persisted value in user defaults.
    @Test
    func appID_withValue() {
        subject.appID = "📱"
        #expect(subject.appID == "📱")
        #expect(userDefaults.string(forKey: "bwaPreferencesStorage:appId") == "📱")

        subject.appID = "☎️"
        #expect(subject.appID == "☎️")
        #expect(userDefaults.string(forKey: "bwaPreferencesStorage:appId") == "☎️")

        subject.appID = nil
        #expect(subject.appID == nil)
        #expect(userDefaults.string(forKey: "bwaPreferencesStorage:appId") == nil)
    }

    /// `appLocale`is initially `nil`.
    @Test
    func appLocale_isInitiallyNil() {
        #expect(subject.appLocale == nil)
    }

    /// `appLocale` can be used to get and set the persisted value in user defaults.
    @Test
    func appLocale_withValue() {
        subject.appLocale = "th"
        #expect(subject.appLocale == "th")
        #expect(userDefaults.string(forKey: "bwaPreferencesStorage:appLocale") == "th")

        subject.appLocale = nil
        #expect(subject.appLocale == nil)
        #expect(userDefaults.string(forKey: "bwaPreferencesStorage:appLocale") == nil)
    }

    /// `appTheme` returns `nil` if there isn't a previously stored value.
    @Test
    func appTheme_isInitiallyNil() {
        #expect(subject.appTheme == nil)
    }

    /// `appTheme` can be used to get and set the persisted value in user defaults.
    @Test
    func appTheme_withValue() {
        subject.appTheme = "light"
        #expect(subject.appTheme == "light")
        #expect(userDefaults.string(forKey: "bwaPreferencesStorage:theme") == "light")

        subject.appTheme = nil
        #expect(subject.appTheme == nil)
        #expect(userDefaults.string(forKey: "bwaPreferencesStorage:theme") == nil)
    }

    /// `cardClosedState` returns `false` if there isn't a previously stored value.
    @Test
    func cardClosedState_isInitiallyFalse() {
        #expect(!subject.cardClosedState(card: .passwordManagerDownload))
        #expect(!subject.cardClosedState(card: .passwordManagerSync))
    }

    /// `cardClosedState` can be used to get and set the persisted value in user defaults.
    @Test
    func cardClosedState_withValue() {
        subject.setCardClosedState(card: .passwordManagerDownload)
        #expect(subject.cardClosedState(card: .passwordManagerDownload))
        #expect(userDefaults.bool(forKey: "bwaPreferencesStorage:cardClosedState_passwordManagerDownload"))

        subject.setCardClosedState(card: .passwordManagerSync)
        #expect(subject.cardClosedState(card: .passwordManagerSync))
        #expect(userDefaults.bool(forKey: "bwaPreferencesStorage:cardClosedState_passwordManagerSync"))
    }

    /// `clearClipboardValue(userId:)` returns `.never` if there isn't a previously stored value.
    @Test
    func clearClipboardValue_isInitiallyNever() {
        #expect(subject.clearClipboardValue(userId: "0") == .never)
    }

    /// `clearClipboardValue(userId:)` can be used to get the clear clipboard value for a user.
    @Test
    func clearClipboardValue_withValue() {
        subject.setClearClipboardValue(.tenSeconds, userId: "1")
        subject.setClearClipboardValue(.never, userId: "2")

        #expect(subject.clearClipboardValue(userId: "1") == .tenSeconds)
        #expect(subject.clearClipboardValue(userId: "2") == .never)
        #expect(userDefaults.integer(forKey: "bwaPreferencesStorage:clearClipboard_1") == 10)
        #expect(userDefaults.integer(forKey: "bwaPreferencesStorage:clearClipboard_2") == -1)
    }

    /// `defaultSaveOption` returns `.none` if there isn't a previously stored value or if a previously
    /// stored value is not a valid option
    @Test
    func defaultSaveOption_isInitiallyNone() {
        #expect(subject.defaultSaveOption == .none)

        userDefaults.set("An invalid value", forKey: "bwaPreferencesStorage:defaultSaveOption")
        #expect(subject.defaultSaveOption == .none)
    }

    /// `defaultSaveOption` can be used to get and set the default save option.
    @Test
    func defaultSaveOption_withValue() {
        subject.defaultSaveOption = .saveToBitwarden
        #expect(subject.defaultSaveOption == .saveToBitwarden)
        #expect(userDefaults.string(forKey: "bwaPreferencesStorage:defaultSaveOption") == "saveToBitwarden")

        subject.defaultSaveOption = .saveHere
        #expect(subject.defaultSaveOption == .saveHere)
        #expect(userDefaults.string(forKey: "bwaPreferencesStorage:defaultSaveOption") == "saveHere")

        subject.defaultSaveOption = .none
        #expect(subject.defaultSaveOption == .none)
        #expect(userDefaults.string(forKey: "bwaPreferencesStorage:defaultSaveOption") == "none")
    }

    /// `flightRecorderData` returns `nil` if there isn't any previously stored flight recorder data.
    @Test
    func flightRecorderData_isInitiallyNil() {
        #expect(subject.flightRecorderData == nil)
    }

    /// `flightRecorderData` can be used to get and set the flight recorder data.
    @Test
    func flightRecorderData_withValue() throws {
        let flightRecorderData = FlightRecorderData(
            activeLog: FlightRecorderData.LogMetadata(duration: .eightHours, startDate: .now),
            inactiveLogs: [],
        )
        subject.flightRecorderData = flightRecorderData

        let data = try #require(
            userDefaults.string(forKey: "bwaPreferencesStorage:flightRecorderData")?
                .data(using: .utf8),
        )
        let decodedData = try JSONDecoder().decode(FlightRecorderData.self, from: data)
        #expect(decodedData == flightRecorderData)

        subject.flightRecorderData = nil
        #expect(userDefaults.string(forKey: "bwaPreferencesStorage:flightRecorderData") == nil)
    }

    /// `hasSeenDefaultSaveOptionPrompt` returns `false` if there isn't a 'defaultSaveOption` value stored, and `true`
    /// when there is a value stored.
    @Test
    func hasSeenDefaultSaveOptionPrompt() {
        #expect(!subject.hasSeenDefaultSaveOptionPrompt)

        subject.defaultSaveOption = .none
        #expect(subject.hasSeenDefaultSaveOptionPrompt)
    }

    /// `disableWebIcons` returns `false` if there isn't a previously stored value.
    @Test
    func disableWebIcons_isInitiallyFalse() {
        #expect(!subject.disableWebIcons)
    }

    /// `disableWebIcons` can be used to get and set the persisted value in user defaults.
    @Test
    func disableWebIcons_withValue() {
        subject.disableWebIcons = true
        #expect(subject.disableWebIcons)
        #expect(userDefaults.bool(forKey: "bwaPreferencesStorage:disableFavicon"))

        subject.disableWebIcons = false
        #expect(!subject.disableWebIcons)
        #expect(!userDefaults.bool(forKey: "bwaPreferencesStorage:disableFavicon"))
    }

    /// `hasSyncedAccount(name:)` can be used to get and set if the user has synced previously with a given account.
    /// Account names should be hashed so as to not appear in plaintext.
    @Test
    func hasSyncedAccount_withValue() {
        let accountName = "test@example.com | vault.bitwarden.com"
        subject.setHasSyncedAccount(name: accountName)
        #expect(subject.hasSyncedAccount(name: accountName))

        // Doesn't store the account as plain text:
        #expect(!userDefaults.bool(forKey: "bwaPreferencesStorage:hasSyncedAccount_\(accountName)"))

        // Stores with the hashed value:
        #expect(userDefaults.bool(
            forKey: "bwaPreferencesStorage:hasSyncedAccount_\(accountName.hexSHA256Hash)",
        ))

        // A new account that we've not synced before defaults to `false`
        #expect(!subject.hasSyncedAccount(name: "New Account"))
    }

    /// `isBiometricAuthenticationEnabled` returns false if there is no previous value.
    @Test
    func isBiometricAuthenticationEnabled_isInitiallyFalse() {
        #expect(!subject.isBiometricAuthenticationEnabled(userId: "-1"))
    }

    /// `isBiometricAuthenticationEnabled` can be used to get the biometric unlock preference for a user.
    @Test
    func isBiometricAuthenticationEnabled_withValue() {
        subject.setBiometricAuthenticationEnabled(false, for: "0")
        subject.setBiometricAuthenticationEnabled(true, for: "1")

        #expect(!subject.isBiometricAuthenticationEnabled(userId: "0"))
        #expect(subject.isBiometricAuthenticationEnabled(userId: "1"))

        subject.setBiometricAuthenticationEnabled(true, for: "0")
        subject.setBiometricAuthenticationEnabled(false, for: "1")

        #expect(subject.isBiometricAuthenticationEnabled(userId: "0"))
        #expect(!subject.isBiometricAuthenticationEnabled(userId: "1"))
    }

    /// `lastActiveTime(userId:)` returns `nil` if there isn't a previously stored value.
    @Test
    func lastActiveTime_isInitiallyNil() {
        #expect(subject.lastActiveTime(userId: "-1") == nil)
    }

    /// `lastActiveTime(userId:)` can be used to get the last active time for a user.
    @Test
    func lastActiveTime_withValue() {
        let date1 = Date(year: 2023, month: 12, day: 1)
        let date2 = Date(year: 2023, month: 10, day: 2)

        subject.setLastActiveTime(date1, userId: "1")
        subject.setLastActiveTime(date2, userId: "2")

        #expect(subject.lastActiveTime(userId: "1") == date1)
        #expect(subject.lastActiveTime(userId: "2") == date2)
    }

    /// `migrationVersion` returns `0` if there isn't a previously stored value.
    @Test
    func migrationVersion_isInitiallyZero() {
        #expect(subject.migrationVersion == 0)
    }

    /// `migrationVersion` can be used to get and set the migration version.
    @Test
    func migrationVersion_withValue() {
        subject.migrationVersion = 1
        #expect(userDefaults.integer(forKey: "bwaPreferencesStorage:migrationVersion") == 1)
        #expect(subject.migrationVersion == 1)

        subject.migrationVersion = 2
        #expect(userDefaults.integer(forKey: "bwaPreferencesStorage:migrationVersion") == 2)
        #expect(subject.migrationVersion == 2)
    }

    /// `.vaultTimeout(userId:)` returns the correct vault timeout value.
    @Test
    func vaultTimeout() {
        subject.setVaultTimeout(minutes: 60, userId: "1")

        #expect(subject.vaultTimeout(userId: "1") == 60)
        #expect(userDefaults.double(forKey: "bwaPreferencesStorage:vaultTimeout_1") == 60)
    }
}
