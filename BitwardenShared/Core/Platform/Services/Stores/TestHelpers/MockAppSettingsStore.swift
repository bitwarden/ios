import Combine
import Foundation

@testable import BitwardenShared

class MockAppSettingsStore: AppSettingsStore {
    var addSitePromptShown = false
    var allowSyncOnRefreshes = [String: Bool]()
    var appId: String?
    var appLocale: String?
    var appTheme: String?
    var biometricIntegrityStateLegacy: String?
    var disableWebIcons = false
    var introCarouselShown = false
    var lastUserShouldConnectToWatch = false
    var loginRequest: LoginRequestNotification?
    var migrationVersion = 0
    var preAuthEnvironmentUrls: EnvironmentUrlData?
    var preAuthServerConfig: BitwardenShared.ServerConfig?
    var rememberedEmail: String?
    var rememberedOrgIdentifier: String?

    var biometricAuthenticationEnabled = [String: Bool?]()
    var biometricIntegrityStates = [String: String?]()
    var clearClipboardValues = [String: ClearClipboardValue]()
    var connectToWatchByUserId = [String: Bool]()
    var defaultUriMatchTypeByUserId = [String: UriMatchType]()
    var disableAutoTotpCopyByUserId = [String: Bool]()
    var encryptedPinByUserId = [String: String]()
    var encryptedPrivateKeys = [String: String]()
    var encryptedUserKeys = [String: String]()
    var eventsByUserId = [String: [EventData]]()
    var featureFlags = [String: Bool]()
    var lastActiveTime = [String: Date]()
    var lastSyncTimeByUserId = [String: Date]()
    var masterPasswordHashes = [String: String]()
    var notificationsLastRegistrationDates = [String: Date]()
    var passwordGenerationOptions = [String: PasswordGenerationOptions]()
    var pinProtectedUserKey = [String: String]()
    var serverConfig = [String: ServerConfig]()
    var shouldTrustDevice = [String: Bool?]()
    var timeoutAction = [String: Int]()
    var twoFactorTokens = [String: String]()
    var usesKeyConnector = [String: Bool]()
    var vaultTimeout = [String: Int]()
    var state: State? {
        didSet {
            activeIdSubject.send(state?.activeUserId)
        }
    }

    var unsuccessfulUnlockAttempts = [String: Int]()
    var usernameGenerationOptions = [String: UsernameGenerationOptions]()

    lazy var activeIdSubject = CurrentValueSubject<String?, Never>(self.state?.activeUserId)

    func allowSyncOnRefresh(userId: String) -> Bool {
        allowSyncOnRefreshes[userId] ?? false
    }

    func clearClipboardValue(userId: String) -> ClearClipboardValue {
        clearClipboardValues[userId] ?? .never
    }

    func connectToWatch(userId: String) -> Bool {
        connectToWatchByUserId[userId] ?? false
    }

    func defaultUriMatchType(userId: String) -> UriMatchType? {
        defaultUriMatchTypeByUserId[userId]
    }

    func disableAutoTotpCopy(userId: String) -> Bool {
        disableAutoTotpCopyByUserId[userId] ?? false
    }

    func encryptedPin(userId: String) -> String? {
        encryptedPinByUserId[userId]
    }

    func encryptedPrivateKey(userId: String) -> String? {
        encryptedPrivateKeys[userId]
    }

    func encryptedUserKey(userId: String) -> String? {
        encryptedUserKeys[userId]
    }

    func events(userId: String) -> [EventData] {
        eventsByUserId[userId] ?? []
    }

    func featureFlag(name: String) -> Bool? {
        featureFlags[name]
    }

    func lastActiveTime(userId: String) -> Date? {
        lastActiveTime[userId]
    }

    func lastSyncTime(userId: String) -> Date? {
        lastSyncTimeByUserId[userId]
    }

    func masterPasswordHash(userId: String) -> String? {
        masterPasswordHashes[userId]
    }

    func notificationsLastRegistrationDate(userId: String) -> Date? {
        notificationsLastRegistrationDates[userId]
    }

    func passwordGenerationOptions(userId: String) -> PasswordGenerationOptions? {
        passwordGenerationOptions[userId]
    }

    func pinProtectedUserKey(userId: String) -> String? {
        pinProtectedUserKey[userId]
    }

    func twoFactorToken(email: String) -> String? {
        twoFactorTokens[email]
    }

    func serverConfig(userId: String) -> ServerConfig? {
        serverConfig[userId]
    }

    func setAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool?, userId: String) {
        allowSyncOnRefreshes[userId] = allowSyncOnRefresh
    }

    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String) {
        clearClipboardValues[userId] = clearClipboardValue
    }

    func setConnectToWatch(_ connectToWatch: Bool, userId: String) {
        connectToWatchByUserId[userId] = connectToWatch
    }

    func setDefaultUriMatchType(_ uriMatchType: UriMatchType?, userId: String) {
        defaultUriMatchTypeByUserId[userId] = uriMatchType
    }

    func setDisableAutoTotpCopy(_ disableAutoTotpCopy: Bool?, userId: String) {
        disableAutoTotpCopyByUserId[userId] = disableAutoTotpCopy
    }

    func setEncryptedPin(_ encryptedPin: String?, userId: String) {
        encryptedPinByUserId[userId] = encryptedPin
    }

    func setEncryptedPrivateKey(key: String?, userId: String) {
        guard let key else {
            encryptedPrivateKeys.removeValue(forKey: userId)
            return
        }
        encryptedPrivateKeys[userId] = key
    }

    func setEncryptedUserKey(key: String?, userId: String) {
        guard let key else {
            encryptedUserKeys.removeValue(forKey: userId)
            return
        }
        encryptedUserKeys[userId] = key
    }

    func setEvents(_ events: [EventData], userId: String) {
        eventsByUserId[userId] = events
    }

    func setFeatureFlag(name: String, value: Bool?) {
        featureFlags[name] = value
    }

    func setLastActiveTime(_ date: Date?, userId: String) {
        lastActiveTime[userId] = date
    }

    func setLastSyncTime(_ date: Date?, userId: String) {
        lastSyncTimeByUserId[userId] = date
    }

    func setMasterPasswordHash(_ hash: String?, userId: String) {
        masterPasswordHashes[userId] = hash
    }

    func setNotificationsLastRegistrationDate(_ date: Date?, userId: String) {
        notificationsLastRegistrationDates[userId] = date
    }

    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions?, userId: String) {
        guard let options else {
            passwordGenerationOptions.removeValue(forKey: userId)
            return
        }
        passwordGenerationOptions[userId] = options
    }

    func setPinProtectedUserKey(key: String?, userId: String) {
        pinProtectedUserKey[userId] = key
    }

    func setServerConfig(_ config: ServerConfig?, userId: String) {
        serverConfig[userId] = config
    }

    func setShouldTrustDevice(shouldTrustDevice: Bool?, userId: String) {
        self.shouldTrustDevice[userId] = shouldTrustDevice
    }

    func setTimeoutAction(key: SessionTimeoutAction, userId: String) {
        timeoutAction[userId] = key.rawValue
    }

    func setTwoFactorToken(_ token: String?, email: String) {
        twoFactorTokens[email] = token
    }

    func setUnsuccessfulUnlockAttempts(_ attempts: Int, userId: String) {
        unsuccessfulUnlockAttempts[userId] = attempts
    }

    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions?, userId: String) {
        guard let options else {
            usernameGenerationOptions.removeValue(forKey: userId)
            return
        }
        usernameGenerationOptions[userId] = options
    }

    func setUsesKeyConnector(_ usesKeyConnector: Bool, userId: String) {
        self.usesKeyConnector[userId] = usesKeyConnector
    }

    func setVaultTimeout(minutes: Int, userId: String) {
        vaultTimeout[userId] = minutes
    }

    func shouldTrustDevice(userId: String) -> Bool? {
        shouldTrustDevice[userId] ?? false
    }

    func timeoutAction(userId: String) -> Int? {
        timeoutAction[userId]
    }

    func unsuccessfulUnlockAttempts(userId: String) -> Int {
        unsuccessfulUnlockAttempts[userId] ?? 0
    }

    func usernameGenerationOptions(userId: String) -> UsernameGenerationOptions? {
        usernameGenerationOptions[userId]
    }

    func usesKeyConnector(userId: String) -> Bool {
        usesKeyConnector[userId] ?? false
    }

    func vaultTimeout(userId: String) -> Int? {
        vaultTimeout[userId]
    }

    func activeAccountIdPublisher() -> AnyPublisher<String?, Never> {
        activeIdSubject.eraseToAnyPublisher()
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
