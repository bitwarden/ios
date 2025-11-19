import BitwardenKit
import Combine
import Foundation

@testable import BitwardenShared

// swiftlint:disable file_length

class MockAppSettingsStore: AppSettingsStore { // swiftlint:disable:this type_body_length
    var accessTokenExpirationDateByUserId = [String: Date]()
    var accountKeys = [String: PrivateKeysResponseModel]()
    var accountSetupAutofill = [String: AccountSetupProgress]()
    var accountSetupImportLogins = [String: AccountSetupProgress]()
    var accountSetupVaultUnlock = [String: AccountSetupProgress]()
    var addSitePromptShown = false
    var allowSyncOnRefreshes = [String: Bool]()
    var allowUniversalClipboardByUserId = [String: Bool]()
    var appId: String?
    var appLocale: String?
    var appRehydrationState = [String: AppRehydrationState]()
    var appTheme: String?
    var cachedActiveUserId: String?
    var disableWebIcons = false
    var flightRecorderData: FlightRecorderData?
    var introCarouselShown = false
    var lastUserShouldConnectToWatch = false
    var learnGeneratorActionCardStatus: AccountSetupProgress = .incomplete
    var learnNewLoginActionCardStatus: AccountSetupProgress = .incomplete
    var loginRequest: LoginRequestNotification?
    var migrationVersion = 0
    var overrideDebugFeatureFlagCalled = false
    var pendingAppIntentActions: [PendingAppIntentAction]?
    var preAuthEnvironmentURLs: EnvironmentURLData?
    var preAuthServerConfig: ServerConfig?
    var rememberedEmail: String?
    var rememberedOrgIdentifier: String?
    var reviewPromptData: BitwardenShared.ReviewPromptData?

    var biometricAuthenticationEnabled = [String: Bool?]()
    var clearClipboardValues = [String: ClearClipboardValue]()
    var connectToWatchByUserId = [String: Bool]()
    var defaultUriMatchTypeByUserId = [String: UriMatchType]()
    var disableAutoTotpCopyByUserId = [String: Bool]()
    var encryptedPinByUserId = [String: String]()
    var encryptedPrivateKeys = [String: String]()
    var encryptedUserKeys = [String: String]()
    var eventsByUserId = [String: [EventData]]()
    var featureFlags = [String: Bool]()
    var hasPerformedSyncAfterLogin = [String: Bool]()
    var lastActiveTime = [String: Date]()
    var lastSyncTimeByUserId = [String: Date]()
    var manuallyLockedAccounts = [String: Bool]()
    var masterPasswordHashes = [String: String]()
    var notificationsLastRegistrationDates = [String: Date]()
    var passwordGenerationOptions = [String: PasswordGenerationOptions]()
    var pinProtectedUserKey = [String: String]()
    var pinProtectedUserKeyEnvelope = [String: String]()
    var accountCreationEnvironmentURLs = [String: EnvironmentURLData]()
    var serverConfig = [String: ServerConfig]()
    var shouldTrustDevice = [String: Bool?]()
    var siriAndShortcutsAccess = [String: Bool]()
    var syncToAuthenticatorByUserId = [String: Bool]()
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

    var activeIdSubject = CurrentValueSubject<String?, Never>(nil)

    func accessTokenExpirationDate(userId: String) -> Date? {
        accessTokenExpirationDateByUserId[userId]
    }

    func accountKeys(userId: String) -> PrivateKeysResponseModel? {
        accountKeys[userId]
    }

    func accountSetupAutofill(userId: String) -> AccountSetupProgress? {
        accountSetupAutofill[userId]
    }

    func accountSetupImportLogins(userId: String) -> AccountSetupProgress? {
        accountSetupImportLogins[userId]
    }

    func accountSetupVaultUnlock(userId: String) -> AccountSetupProgress? {
        accountSetupVaultUnlock[userId]
    }

    func allowSyncOnRefresh(userId: String) -> Bool {
        allowSyncOnRefreshes[userId] ?? false
    }

    func allowUniversalClipboard(userId: String) -> Bool {
        allowUniversalClipboardByUserId[userId] ?? false
    }

    func appRehydrationState(userId: String) -> BitwardenShared.AppRehydrationState? {
        appRehydrationState[userId]
    }

    func clearClipboardValue(userId: String) -> ClearClipboardValue {
        clearClipboardValues[userId] ?? .never
    }

    func connectToWatch(userId: String) -> Bool {
        connectToWatchByUserId[userId] ?? false
    }

    func debugFeatureFlag(name: String) -> Bool? {
        featureFlags[name]
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

    func hasPerformedSyncAfterLogin(userId: String) -> Bool {
        hasPerformedSyncAfterLogin[userId] ?? false
    }

    func lastActiveTime(userId: String) -> Date? {
        lastActiveTime[userId]
    }

    func lastSyncTime(userId: String) -> Date? {
        lastSyncTimeByUserId[userId]
    }

    func manuallyLockedAccount(userId: String) -> Bool {
        manuallyLockedAccounts[userId] ?? false
    }

    func masterPasswordHash(userId: String) -> String? {
        masterPasswordHashes[userId]
    }

    func notificationsLastRegistrationDate(userId: String) -> Date? {
        notificationsLastRegistrationDates[userId]
    }

    func overrideDebugFeatureFlag(name: String, value: Bool?) {
        overrideDebugFeatureFlagCalled = true
        featureFlags[name] = value
    }

    func passwordGenerationOptions(userId: String) -> PasswordGenerationOptions? {
        passwordGenerationOptions[userId]
    }

    func pinProtectedUserKey(userId: String) -> String? {
        pinProtectedUserKey[userId]
    }

    func pinProtectedUserKeyEnvelope(userId: String) -> String? {
        pinProtectedUserKeyEnvelope[userId]
    }

    func accountCreationEnvironmentURLs(email: String) -> EnvironmentURLData? {
        accountCreationEnvironmentURLs[email]
    }

    func twoFactorToken(email: String) -> String? {
        twoFactorTokens[email]
    }

    func serverConfig(userId: String) -> ServerConfig? {
        serverConfig[userId]
    }

    func setAccessTokenExpirationDate(_ expirationDate: Date?, userId: String) {
        accessTokenExpirationDateByUserId[userId] = expirationDate
    }

    func setAccountKeys(_ keys: BitwardenShared.PrivateKeysResponseModel?, userId: String) {
        accountKeys[userId] = keys
    }

    func setAccountSetupAutofill(_ autofillSetup: AccountSetupProgress?, userId: String) {
        accountSetupAutofill[userId] = autofillSetup
    }

    func setAccountSetupImportLogins(_ importLoginsSetup: AccountSetupProgress?, userId: String) {
        accountSetupImportLogins[userId] = importLoginsSetup
    }

    func setAccountSetupVaultUnlock(_ vaultUnlockSetup: AccountSetupProgress?, userId: String) {
        accountSetupVaultUnlock[userId] = vaultUnlockSetup
    }

    func setAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool?, userId: String) {
        allowSyncOnRefreshes[userId] = allowSyncOnRefresh
    }

    func setAllowUniversalClipboard(_ allowUniversalClipboard: Bool?, userId: String) {
        allowUniversalClipboardByUserId[userId] = allowUniversalClipboard
    }

    func setAppRehydrationState(_ state: BitwardenShared.AppRehydrationState?, userId: String) {
        guard state != nil else {
            appRehydrationState.removeValue(forKey: userId)
            return
        }
        appRehydrationState[userId] = state
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

    func setHasPerformedSyncAfterLogin(_ hasBeenPerformed: Bool?, userId: String) {
        guard let hasBeenPerformed else {
            hasPerformedSyncAfterLogin.removeValue(forKey: userId)
            return
        }
        hasPerformedSyncAfterLogin[userId] = hasBeenPerformed
    }

    func setLastActiveTime(_ date: Date?, userId: String) {
        lastActiveTime[userId] = date
    }

    func setLastSyncTime(_ date: Date?, userId: String) {
        lastSyncTimeByUserId[userId] = date
    }

    func setManuallyLockedAccount(_ isLocked: Bool, userId: String) {
        manuallyLockedAccounts[userId] = isLocked
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

    func setPinProtectedUserKeyEnvelope(key: String?, userId: String) {
        pinProtectedUserKeyEnvelope[userId] = key
    }

    func setAccountCreationEnvironmentURLs(environmentURLData: EnvironmentURLData, email: String) {
        accountCreationEnvironmentURLs[email] = environmentURLData
    }

    func setServerConfig(_ config: ServerConfig?, userId: String) {
        serverConfig[userId] = config
    }

    func setShouldTrustDevice(shouldTrustDevice: Bool?, userId: String) {
        self.shouldTrustDevice[userId] = shouldTrustDevice
    }

    func setSiriAndShortcutsAccess(_ siriAndShortcutsAccess: Bool, userId: String) {
        self.siriAndShortcutsAccess[userId] = siriAndShortcutsAccess
    }

    func setSyncToAuthenticator(_ syncToAuthenticator: Bool, userId: String) {
        syncToAuthenticatorByUserId[userId] = syncToAuthenticator
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

    func siriAndShortcutsAccess(userId: String) -> Bool {
        siriAndShortcutsAccess[userId] ?? false
    }

    func syncToAuthenticator(userId: String) -> Bool {
        syncToAuthenticatorByUserId[userId] ?? false
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

    func setBiometricAuthenticationEnabled(_ isEnabled: Bool?, for userId: String) {
        guard isEnabled != nil else {
            biometricAuthenticationEnabled.removeValue(forKey: userId)
            return
        }
        biometricAuthenticationEnabled[userId] = isEnabled
    }
}
