import Combine
import Foundation

@testable import BitwardenShared

class MockStateService: StateService { // swiftlint:disable:this type_body_length
    var accountEncryptionKeys = [String: AccountEncryptionKeys]()
    var accountTokens: Account.AccountTokens?
    var accountVolatileData: [String: AccountVolatileData] = [:]
    var accountsAdded = [Account]()
    var accountsLoggedOut = [String]()
    var activeAccount: Account?
    var accounts: [Account]?
    var addSitePromptShown = false
    var allowSyncOnRefresh = [String: Bool]()
    var appLanguage: LanguageOption = .default
    var appTheme: AppTheme?
    var biometricsEnabled = [String: Bool]()
    var biometricIntegrityStates = [String: String]()
    var capturedUserId: String?
    var clearClipboardValues = [String: ClearClipboardValue]()
    var clearClipboardResult: Result<Void, Error> = .success(())
    var connectToWatchByUserId = [String: Bool]()
    var connectToWatchResult: Result<Void, Error> = .success(())
    var connectToWatchSubject = CurrentValueSubject<(String?, Bool), Never>((nil, false))
    var timeProvider = MockTimeProvider(.currentTime)
    var defaultUriMatchTypeByUserId = [String: UriMatchType]()
    var disableAutoTotpCopyByUserId = [String: Bool]()
    var doesActiveAccountHavePremiumCalled = false
    var doesActiveAccountHavePremiumResult: Result<Bool, Error> = .success(true)
    var encryptedPinByUserId = [String: String]()
    var environmentUrls = [String: EnvironmentUrlData]()
    var environmentUrlsError: Error?
    var eventsResult: Result<Void, Error> = .success(())
    var events = [String: [EventData]]()
    var forcePasswordResetReason = [String: ForcePasswordResetReason]()
    var introCarouselShown = false
    var isAuthenticated = [String: Bool]()
    var isAuthenticatedError: Error?
    var lastActiveTime = [String: Date]()
    var loginRequest: LoginRequestNotification?
    var logoutAccountUserInitiated = false
    var getAccountEncryptionKeysError: Error?
    // swiftlint:disable:next identifier_name
    var getAccountHasBeenUnlockedInteractivelyResult: Result<Bool, Error> = .success(false)
    var getBiometricAuthenticationEnabledResult: Result<Void, Error> = .success(())
    var getBiometricIntegrityStateError: Error?
    var lastSyncTimeByUserId = [String: Date]()
    var lastSyncTimeSubject = CurrentValueSubject<Date?, Never>(nil)
    var lastUserShouldConnectToWatch = false
    var masterPasswordHashes = [String: String]()
    var needsVaultUnlockSetup = [String: Bool]()
    var notificationsLastRegistrationDates = [String: Date]()
    var notificationsLastRegistrationError: Error?
    var passwordGenerationOptions = [String: PasswordGenerationOptions]()
    var pinProtectedUserKeyValue = [String: String]()
    var preAuthEnvironmentUrls: EnvironmentUrlData?
    var accountCreationEnvironmentUrls = [String: EnvironmentUrlData]()
    var preAuthServerConfig: ServerConfig?
    var rememberedOrgIdentifier: String?
    var showWebIcons = true
    var showWebIconsSubject = CurrentValueSubject<Bool, Never>(true)
    var timeoutAction = [String: SessionTimeoutAction]()
    var serverConfig = [String: ServerConfig]()
    var setAccountHasBeenUnlockedInteractivelyHasBeenCalled = false // swiftlint:disable:this identifier_name
    // swiftlint:disable:next identifier_name
    var setAccountHasBeenUnlockedInteractivelyResult: Result<Void, Error> = .success(())
    var setBiometricAuthenticationEnabledResult: Result<Void, Error> = .success(())
    var setBiometricIntegrityStateError: Error?
    var shouldTrustDevice = [String: Bool?]()
    var twoFactorTokens = [String: String]()
    var unsuccessfulUnlockAttempts = [String: Int]()
    var updateProfileResponse: ProfileResponseModel?
    var updateProfileUserId: String?
    var userHasMasterPassword = [String: Bool]()
    var userIds = [String]()
    var usernameGenerationOptions = [String: UsernameGenerationOptions]()
    var usesKeyConnector = [String: Bool]()
    var vaultTimeout = [String: SessionTimeoutValue]()

    lazy var activeIdSubject = CurrentValueSubject<String?, Never>(self.activeAccount?.profile.userId)
    lazy var appThemeSubject = CurrentValueSubject<AppTheme, Never>(self.appTheme ?? .default)

    func addAccount(_ account: Account) async {
        accountsAdded.append(account)
        activeAccount = account
    }

    func clearPins() async throws {
        let userId = try unwrapUserId(nil)
        accountVolatileData.removeValue(forKey: userId)
        pinProtectedUserKeyValue[userId] = nil
        encryptedPinByUserId[userId] = nil
    }

    func updateProfile(from response: ProfileResponseModel, userId: String) async {
        updateProfileResponse = response
        updateProfileUserId = userId
    }

    func deleteAccount() async throws {
        accounts?.removeAll(where: { account in
            account == activeAccount
        })
    }

    func doesActiveAccountHavePremium() async throws -> Bool {
        doesActiveAccountHavePremiumCalled = true
        return try doesActiveAccountHavePremiumResult.get()
    }

    func getAccountEncryptionKeys(userId: String?) async throws -> AccountEncryptionKeys {
        if let error = getAccountEncryptionKeysError {
            throw error
        }
        let id = try await getAccountIdOrActiveId(userId: userId)
        guard let encryptionKeys = accountEncryptionKeys[id]
        else {
            throw StateServiceError.noActiveAccount
        }
        return encryptionKeys
    }

    func getAccountHasBeenUnlockedInteractively(userId: String?) async throws -> Bool {
        try getAccountHasBeenUnlockedInteractivelyResult.get()
    }

    func getAccount(userId: String?) async throws -> BitwardenShared.Account {
        let id = try await getAccountIdOrActiveId(userId: userId)
        if let activeAccount,
           activeAccount.profile.userId == id {
            return activeAccount
        }
        guard let knownAccounts = accounts,
              let match = knownAccounts.first(where: { $0.profile.userId == id }) else {
            throw StateServiceError.noAccounts
        }
        return match
    }

    func getAccounts() async throws -> [Account] {
        guard let accounts else {
            throw StateServiceError.noAccounts
        }
        return accounts
    }

    func getAccountIdOrActiveId(userId: String?) async throws -> String {
        if let userId {
            return userId
        }
        return try await getActiveAccountId()
    }

    func getActiveAccountId() async throws -> String {
        guard let activeAccount else { throw StateServiceError.noActiveAccount }
        return activeAccount.profile.userId
    }

    func getAddSitePromptShown() async -> Bool {
        addSitePromptShown
    }

    func getAppTheme() async -> AppTheme {
        appTheme ?? .default
    }

    func getAllowSyncOnRefresh(userId: String?) async throws -> Bool {
        let userId = try unwrapUserId(userId)
        return allowSyncOnRefresh[userId] ?? false
    }

    func getClearClipboardValue(userId: String?) async throws -> ClearClipboardValue {
        try clearClipboardResult.get()
        let userId = try unwrapUserId(userId)
        return clearClipboardValues[userId] ?? .never
    }

    func getConnectToWatch(userId: String?) async throws -> Bool {
        try connectToWatchResult.get()
        let userId = try unwrapUserId(userId)
        return connectToWatchByUserId[userId] ?? false
    }

    func getDefaultUriMatchType(userId: String?) async throws -> UriMatchType {
        let userId = try unwrapUserId(userId)
        return defaultUriMatchTypeByUserId[userId] ?? .domain
    }

    func getDisableAutoTotpCopy(userId: String?) async throws -> Bool {
        let userId = try unwrapUserId(userId)
        return disableAutoTotpCopyByUserId[userId] ?? false
    }

    func getEncryptedPin(userId: String?) async throws -> String? {
        let userId = try unwrapUserId(userId)
        return encryptedPinByUserId[userId] ?? nil
    }

    func getEnvironmentUrls(userId: String?) async throws -> EnvironmentUrlData? {
        if let environmentUrlsError {
            throw environmentUrlsError
        }
        let userId = try unwrapUserId(userId)
        return environmentUrls[userId]
    }

    func getEvents(userId: String?) async throws -> [EventData] {
        try eventsResult.get()
        let userId = try unwrapUserId(userId)
        return events[userId] ?? []
    }

    func getIntroCarouselShown() async -> Bool {
        introCarouselShown
    }

    func getLastActiveTime(userId: String?) async throws -> Date? {
        let userId = try unwrapUserId(userId)
        return lastActiveTime[userId]
    }

    func getLastSyncTime(userId: String?) async throws -> Date? {
        let userId = try unwrapUserId(userId)
        return lastSyncTimeByUserId[userId]
    }

    func getLoginRequest() async -> LoginRequestNotification? {
        loginRequest
    }

    func getMasterPasswordHash(userId: String?) async throws -> String? {
        let userId = try unwrapUserId(userId)
        return masterPasswordHashes[userId]
    }

    func getNeedsVaultUnlockSetup(userId: String?) async throws -> Bool {
        let userId = try unwrapUserId(userId)
        return needsVaultUnlockSetup[userId] ?? false
    }

    func getNotificationsLastRegistrationDate(userId: String?) async throws -> Date? {
        if let notificationsLastRegistrationError {
            throw notificationsLastRegistrationError
        }
        let userId = try unwrapUserId(userId)
        return notificationsLastRegistrationDates[userId]
    }

    func getPasswordGenerationOptions(userId: String?) async throws -> PasswordGenerationOptions? {
        let userId = try unwrapUserId(userId)
        return passwordGenerationOptions[userId]
    }

    func getPreAuthEnvironmentUrls() async -> EnvironmentUrlData? {
        preAuthEnvironmentUrls
    }

    func getAccountCreationEnvironmentUrls(email: String) async -> EnvironmentUrlData? {
        accountCreationEnvironmentUrls[email]
    }

    func getPreAuthServerConfig() async -> BitwardenShared.ServerConfig? {
        preAuthServerConfig
    }

    func getServerConfig(userId: String?) async throws -> ServerConfig? {
        let userId = try unwrapUserId(userId)
        return serverConfig[userId]
    }

    func getShouldTrustDevice(userId: String) async -> Bool? {
        shouldTrustDevice[userId] ?? false
    }

    func getShowWebIcons() async -> Bool {
        showWebIcons
    }

    func getTimeoutAction(userId: String?) async throws -> SessionTimeoutAction {
        let userId = try unwrapUserId(userId)
        return timeoutAction[userId] ?? .lock
    }

    func getTwoFactorToken(email: String) async -> String? {
        twoFactorTokens[email]
    }

    func getUnsuccessfulUnlockAttempts(userId: String?) async throws -> Int {
        let userId = try unwrapUserId(userId)
        return unsuccessfulUnlockAttempts[userId] ?? 0
    }

    func getUserHasMasterPassword(userId: String?) async throws -> Bool {
        let userId = try unwrapUserId(userId)
        return userHasMasterPassword[userId] ?? true
    }

    func getUserIds(email: String) async -> [String] {
        userIds
    }

    func getUsernameGenerationOptions(userId: String?) async throws -> UsernameGenerationOptions? {
        let userId = try unwrapUserId(userId)
        return usernameGenerationOptions[userId]
    }

    func getUsesKeyConnector(userId: String?) async throws -> Bool {
        let userId = try unwrapUserId(userId)
        return usesKeyConnector[userId] ?? false
    }

    func getVaultTimeout(userId: String?) async throws -> SessionTimeoutValue {
        let userId = try unwrapUserId(userId)
        return vaultTimeout[userId] ?? .immediately
    }

    func isAuthenticated(userId: String?) async throws -> Bool {
        let userId = try unwrapUserId(userId)
        if let isAuthenticatedError { throw isAuthenticatedError }
        return isAuthenticated[userId] ?? false
    }

    func logoutAccount(userId: String?, userInitiated: Bool) async throws {
        let userId = try unwrapUserId(userId)
        accountsLoggedOut.append(userId)
        logoutAccountUserInitiated = userInitiated
    }

    func pinProtectedUserKey(userId: String?) async throws -> String? {
        let userId = try unwrapUserId(userId)
        return pinProtectedUserKeyValue[userId] ?? nil
    }

    func setAccountEncryptionKeys(_ encryptionKeys: AccountEncryptionKeys, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        accountEncryptionKeys[userId] = encryptionKeys
    }

    func setAccountHasBeenUnlockedInteractively(userId: String?, value: Bool) async throws {
        setAccountHasBeenUnlockedInteractivelyHasBeenCalled = true
        try setAccountHasBeenUnlockedInteractivelyResult.get()
    }

    func setActiveAccount(userId: String) async throws {
        guard let accounts,
              let match = accounts.first(where: { account in
                  account.profile.userId == userId
              }) else {
            throw StateServiceError.noAccounts
        }
        activeAccount = match
    }

    func setAddSitePromptShown(_ shown: Bool) async {
        addSitePromptShown = shown
    }

    func setAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        self.allowSyncOnRefresh[userId] = allowSyncOnRefresh
    }

    func setAppTheme(_ appTheme: AppTheme) async {
        self.appTheme = appTheme
    }

    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String?) async throws {
        try clearClipboardResult.get()
        let userId = try unwrapUserId(userId)
        clearClipboardValues[userId] = clearClipboardValue
    }

    func setConnectToWatch(_ connectToWatch: Bool, userId: String?) async throws {
        try connectToWatchResult.get()
        let userId = try unwrapUserId(userId)
        connectToWatchByUserId[userId] = connectToWatch
    }

    func setDefaultUriMatchType(_ defaultUriMatchType: UriMatchType?, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        defaultUriMatchTypeByUserId[userId] = defaultUriMatchType
    }

    func setDisableAutoTotpCopy(_ disableAutoTotpCopy: Bool, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        disableAutoTotpCopyByUserId[userId] = disableAutoTotpCopy
    }

    func setEncryptedPin(_ pin: String) async throws {
        let userId = try unwrapUserId(nil)
        accountVolatileData[userId, default: AccountVolatileData()].pinProtectedUserKey = pin
    }

    func setEnvironmentUrls(_ environmentUrls: EnvironmentUrlData, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        self.environmentUrls[userId] = environmentUrls
    }

    func setEvents(_ events: [EventData], userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        self.events[userId] = events
    }

    func setForcePasswordResetReason(_ reason: ForcePasswordResetReason?, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        forcePasswordResetReason[userId] = reason
    }

    func setIntroCarouselShown(_ shown: Bool) async {
        introCarouselShown = shown
    }

    func setIsAuthenticated() {
        let account = Account.fixture()
        activeAccount = account
        isAuthenticated[account.profile.userId] = true
    }

    func setLastActiveTime(_ date: Date?, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        lastActiveTime[userId] = timeProvider.presentTime
    }

    func setLastSyncTime(_ date: Date?, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        lastSyncTimeByUserId[userId] = date
    }

    func getLastUserShouldConnectToWatch() async -> Bool {
        lastUserShouldConnectToWatch
    }

    func setLoginRequest(_ loginRequest: LoginRequestNotification?) async {
        self.loginRequest = loginRequest
    }

    func setMasterPasswordHash(_ hash: String?, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        masterPasswordHashes[userId] = hash
    }

    func setNeedsVaultUnlockSetup(_ needsVaultUnlockSetup: Bool, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        self.needsVaultUnlockSetup[userId] = needsVaultUnlockSetup
    }

    func setNotificationsLastRegistrationDate(_ date: Date?, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        notificationsLastRegistrationDates[userId] = date
    }

    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions?, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        passwordGenerationOptions[userId] = options
    }

    func setPinKeys(
        encryptedPin: String,
        pinProtectedUserKey: String,
        requirePasswordAfterRestart: Bool
    ) async throws {
        let userId = try unwrapUserId(nil)
        pinProtectedUserKeyValue[userId] = pinProtectedUserKey
        encryptedPinByUserId[userId] = encryptedPin

        if requirePasswordAfterRestart {
            accountVolatileData[
                userId,
                default: AccountVolatileData()
            ].pinProtectedUserKey = pinProtectedUserKey
        }
    }

    func setPinProtectedUserKeyToMemory(_ pin: String) async throws {
        let userId = try unwrapUserId(nil)
        accountVolatileData[
            userId,
            default: AccountVolatileData()
        ].pinProtectedUserKey = pin
    }

    func setPreAuthEnvironmentUrls(_ urls: BitwardenShared.EnvironmentUrlData) async {
        preAuthEnvironmentUrls = urls
    }

    func setAccountCreationEnvironmentUrls(urls: BitwardenShared.EnvironmentUrlData, email: String) async {
        accountCreationEnvironmentUrls[email] = urls
    }

    func setPreAuthServerConfig(config: BitwardenShared.ServerConfig) async {
        preAuthServerConfig = config
    }

    func setServerConfig(_ config: ServerConfig?, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        serverConfig[userId] = config
    }

    func setShouldTrustDevice(_ shouldTrustDevice: Bool?, userId: String) async {
        self.shouldTrustDevice[userId] = shouldTrustDevice
    }

    func setShowWebIcons(_ showWebIcons: Bool) async {
        self.showWebIcons = showWebIcons
    }

    func setTimeoutAction(action: SessionTimeoutAction, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        timeoutAction[userId] = action
    }

    func setTokens(accessToken: String, refreshToken: String, userId _: String?) async throws {
        accountTokens = Account.AccountTokens(accessToken: accessToken, refreshToken: refreshToken)
    }

    func setTwoFactorToken(_ token: String?, email: String) async {
        twoFactorTokens[email] = token
    }

    func setUnsuccessfulUnlockAttempts(_ attempts: Int, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        unsuccessfulUnlockAttempts[userId] = attempts
    }

    func setUserHasMasterPassword(_ hasMasterPassword: Bool) async throws {
        let userId = try unwrapUserId(nil)
        userHasMasterPassword[userId] = hasMasterPassword
    }

    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions?, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        usernameGenerationOptions[userId] = options
    }

    func setUsesKeyConnector(_ usesKeyConnector: Bool, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        self.usesKeyConnector[userId] = usesKeyConnector
    }

    func setVaultTimeout(value: SessionTimeoutValue, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        vaultTimeout[userId] = value
    }

    /// Attempts to convert a possible user id into an account, or returns the active account.
    ///
    /// - Parameter userId: If nil, the active account is returned. Otherwise, retrieve an account for the id.
    ///
    func unwrapAccount(_ userId: String?) throws -> Account {
        if let userId,
           let activeAccount,
           activeAccount.profile.userId == userId {
            return activeAccount
        } else if let userId,
                  let match = accounts?.first(where: { userId == $0.profile.userId }) {
            return match
        } else if let activeAccount,
                  userId == nil {
            return activeAccount
        } else {
            throw StateServiceError.noAccounts
        }
    }

    /// Attempts to convert a possible user id into a known account id.
    ///
    /// - Parameter userId: If nil, the active account id is returned. Otherwise, validate the id.
    ///
    func unwrapUserId(_ userId: String?) throws -> String {
        if let userId {
            return userId
        } else if let activeAccount {
            return activeAccount.profile.userId
        } else {
            throw StateServiceError.noActiveAccount
        }
    }

    func activeAccountIdPublisher() async -> AnyPublisher<String?, Never> {
        activeIdSubject.eraseToAnyPublisher()
    }

    func appThemePublisher() async -> AnyPublisher<AppTheme, Never> {
        appThemeSubject.eraseToAnyPublisher()
    }

    func connectToWatchPublisher() async -> AnyPublisher<(String?, Bool), Never> {
        connectToWatchSubject.eraseToAnyPublisher()
    }

    func lastSyncTimePublisher() async throws -> AnyPublisher<Date?, Never> {
        lastSyncTimeSubject.eraseToAnyPublisher()
    }

    func showWebIconsPublisher() async -> AnyPublisher<Bool, Never> {
        showWebIconsSubject.eraseToAnyPublisher()
    }
}

// MARK: Biometrics

extension MockStateService {
    func getBiometricAuthenticationEnabled() async throws -> Bool {
        guard let activeAccount else { throw StateServiceError.noActiveAccount }
        try getBiometricAuthenticationEnabledResult.get()
        return biometricsEnabled[activeAccount.profile.userId] ?? false
    }

    func getBiometricIntegrityState() async throws -> String? {
        guard let activeAccount else { throw StateServiceError.noActiveAccount }
        if let getBiometricIntegrityStateError {
            throw getBiometricIntegrityStateError
        }
        return biometricIntegrityStates[activeAccount.profile.userId] ?? nil
    }

    func setBiometricAuthenticationEnabled(_ isEnabled: Bool?) async throws {
        guard let activeAccount else { throw StateServiceError.noActiveAccount }
        try setBiometricAuthenticationEnabledResult.get()
        biometricsEnabled[activeAccount.profile.userId] = isEnabled
    }

    func setBiometricIntegrityState(_ base64EncodedState: String?) async throws {
        guard let activeAccount else { throw StateServiceError.noActiveAccount }
        if let setBiometricIntegrityStateError {
            throw setBiometricIntegrityStateError
        }
        biometricIntegrityStates[activeAccount.profile.userId] = base64EncodedState
    }
} // swiftlint:disable:this file_length
