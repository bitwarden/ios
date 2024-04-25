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
    var hasSeenWelcomeTutorial = false
    var lastUserShouldConnectToWatch = false
    var localUserId: String = "localtest"
    var migrationVersion = 0
    var rememberedEmail: String?
    var rememberedOrgIdentifier: String?

    var approveLoginRequestsByUserId = [String: Bool]()
    var biometricAuthenticationEnabled = [String: Bool?]()
    var biometricIntegrityStates = [String: String?]()
    var clearClipboardValues = [String: ClearClipboardValue]()
    var connectToWatchByUserId = [String: Bool]()
    var disableAutoTotpCopyByUserId = [String: Bool]()
    var encryptedPrivateKeys = [String: String]()
    var encryptedUserKeys = [String: String]()
    var lastActiveTime = [String: Date]()
    var lastSyncTimeByUserId = [String: Date]()
    var masterPasswordHashes = [String: String]()
    var notificationsLastRegistrationDates = [String: Date]()
    var pinKeyEncryptedUserKey = [String: String]()
    var pinProtectedUserKey = [String: String]()
    var secretKeys = [String: String]()
    var timeoutAction = [String: Int]()
    var twoFactorTokens = [String: String]()
    var vaultTimeout = [String: Int?]()

    var unsuccessfulUnlockAttempts = [String: Int]()

    func clearClipboardValue(userId: String) -> ClearClipboardValue {
        clearClipboardValues[userId] ?? .never
    }

    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String) {
        clearClipboardValues[userId] = clearClipboardValue
    }

    func secretKey(userId: String) -> String? {
        secretKeys[userId]
    }

    func setSecretKey(_ key: String, userId: String) {
        secretKeys[userId] = key
    }
}

// MARK: Biometrics

extension MockAppSettingsStore {
    func isBiometricAuthenticationEnabled(userId: String) -> Bool {
        (biometricAuthenticationEnabled[userId] ?? false) ?? false
    }

    func biometricIntegrityState(userId: String) -> String? {
        biometricIntegrityStates[userId] ?? nil
    }

    func setBiometricAuthenticationEnabled(_ isEnabled: Bool?, for userId: String) {
        guard isEnabled != nil else {
            biometricAuthenticationEnabled.removeValue(forKey: userId)
            return
        }
        biometricAuthenticationEnabled[userId] = isEnabled
    }

    func setBiometricIntegrityState(_ base64EncodedIntegrityState: String?, userId: String) {
        guard let base64EncodedIntegrityState else {
            biometricIntegrityStates.removeValue(forKey: userId)
            return
        }
        biometricIntegrityStates[userId] = base64EncodedIntegrityState
    }
}
