import BitwardenKit
import Combine
import Foundation

@testable import AuthenticatorShared

class MockAppSettingsStore: AppSettingsStore {
    var addSitePromptShown = false
    var allowSyncOnRefreshes = [String: Bool]()
    var appId: String?
    var appLocale: String?
    var appTheme: String?
    var disableWebIcons = false
    var defaultSaveOption: DefaultSaveOption = .none
    var flightRecorderData: FlightRecorderData?
    var hasSeenDefaultSaveOptionPrompt = false
    var hasSeenWelcomeTutorial = false
    var lastUserShouldConnectToWatch = false
    var localUserId: String = "localtest"
    var migrationVersion = 0
    var overrideDebugFeatureFlagCalled = false
    var preAuthServerConfig: ServerConfig?
    var rememberedEmail: String?
    var rememberedOrgIdentifier: String?

    var approveLoginRequestsByUserId = [String: Bool]()
    var biometricAuthenticationEnabled = [String: Bool?]()
    var cardClosedStateValues = [ItemListCard: Bool]()
    var clearClipboardValues = [String: ClearClipboardValue]()
    var connectToWatchByUserId = [String: Bool]()
    var disableAutoTotpCopyByUserId = [String: Bool]()
    var encryptedPrivateKeys = [String: String]()
    var encryptedUserKeys = [String: String]()
    var featureFlags = [String: Bool]()
    var hasSyncedAccountValues = [String: Bool]()
    var lastActiveTime = [String: Date]()
    var lastSyncTimeByUserId = [String: Date]()
    var masterPasswordHashes = [String: String]()
    var notificationsLastRegistrationDates = [String: Date]()
    var pinKeyEncryptedUserKey = [String: String]()
    var pinProtectedUserKey = [String: String]()
    var secretKeys = [String: String]()
    var serverConfig = [String: ServerConfig]()
    var timeoutAction = [String: Int]()
    var twoFactorTokens = [String: String]()
    var vaultTimeout = [String: Int]()

    var unsuccessfulUnlockAttempts = [String: Int]()

    func cardClosedState(card: ItemListCard) -> Bool {
        cardClosedStateValues[card] ?? false
    }

    func setCardClosedState(card: ItemListCard) {
        cardClosedStateValues[card] = true
    }

    func clearClipboardValue(userId: String) -> ClearClipboardValue {
        clearClipboardValues[userId] ?? .never
    }

    func debugFeatureFlag(name: String) -> Bool? {
        featureFlags[name]
    }

    func lastActiveTime(userId: String) -> Date? {
        lastActiveTime[userId]
    }

    func overrideDebugFeatureFlag(name: String, value: Bool?) {
        overrideDebugFeatureFlagCalled = true
        featureFlags[name] = value
    }

    func hasSyncedAccount(name: String) -> Bool {
        hasSyncedAccountValues[name] ?? false
    }

    func setHasSyncedAccount(name: String) {
        hasSyncedAccountValues[name] = true
    }

    func secretKey(userId: String) -> String? {
        secretKeys[userId]
    }

    func serverConfig(userId: String) -> ServerConfig? {
        serverConfig[userId]
    }

    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String) {
        clearClipboardValues[userId] = clearClipboardValue
    }

    func setLastActiveTime(_ date: Date?, userId: String) {
        lastActiveTime[userId] = date
    }

    func setSecretKey(_ key: String, userId: String) {
        secretKeys[userId] = key
    }

    func setServerConfig(_ config: ServerConfig?, userId: String) {
        serverConfig[userId] = config
    }

    func setVaultTimeout(minutes: Int, userId: String) {
        vaultTimeout[userId] = minutes
    }

    func vaultTimeout(userId: String) -> Int? {
        vaultTimeout[userId]
    }
}

// MARK: Biometrics

extension MockAppSettingsStore {
    func isBiometricAuthenticationEnabled(userId: String) -> Bool {
        (biometricAuthenticationEnabled[userId] ?? false) ?? false
    }

    func setBiometricAuthenticationEnabled(_ isEnabled: Bool?, for userId: String) {
        guard isEnabled != nil else {
            biometricAuthenticationEnabled.removeValue(forKey: userId)
            return
        }
        biometricAuthenticationEnabled[userId] = isEnabled
    }

}
