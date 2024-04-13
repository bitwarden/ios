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
}
