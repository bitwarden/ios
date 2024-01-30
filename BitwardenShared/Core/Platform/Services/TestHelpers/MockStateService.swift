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
    var allowSyncOnRefresh = [String: Bool]()
    var appLanguage: LanguageOption = .default
    var approveLoginRequestsByUserId = [String: Bool]()
    var appTheme: AppTheme?
    var biometricsEnabled = [String: Bool]()
    var biometricIntegrityStates = [String: String?]()
    var capturedUserId: String?
    var clearClipboardValues = [String: ClearClipboardValue]()
    var clearClipboardResult: Result<Void, Error> = .success(())
    var connectToWatchByUserId = [String: Bool]()
    var connectToWatchResult: Result<Void, Error> = .success(())
    var connectToWatchSubject = CurrentValueSubject<Bool, Never>(false)
    var timeProvider = MockTimeProvider(.currentTime)
    var defaultUriMatchTypeByUserId = [String: UriMatchType]()
    var disableAutoTotpCopyByUserId = [String: Bool]()
    var environmentUrls = [String: EnvironmentUrlData]()
    var lastActiveTime = [String: Date]()
    var loginRequest: LoginRequestNotification?
    var getAccountEncryptionKeysError: Error?
    var getBiometricAuthenticationEnabledResult: Result<Void, Error> = .success(())
    var getBiometricIntegrityStateError: Error?
    var lastSyncTimeByUserId = [String: Date]()
    var lastSyncTimeSubject = CurrentValueSubject<Date?, Never>(nil)
    var lastUserShouldConnectToWatch = false
    var masterPasswordHashes = [String: String]()
    var notificationsLastRegistrationDates = [String: Date]()
    var passwordGenerationOptions = [String: PasswordGenerationOptions]()
    var pinKeyEncryptedUserKeyValue = [String: String]()
    var pinProtectedUserKeyValue = [String: String]()
    var preAuthEnvironmentUrls: EnvironmentUrlData?
    var rememberedOrgIdentifier: String?
    var showWebIcons = true
    var showWebIconsSubject = CurrentValueSubject<Bool, Never>(true)
    var timeoutAction = [String: SessionTimeoutAction]()
    var setBiometricAuthenticationEnabledResult: Result<Void, Error> = .success(())
    var setBiometricIntegrityStateError: Error?
    var twoFactorTokens = [String: String]()
    var unsuccessfulUnlockAttempts = [String: Int]()
    var usernameGenerationOptions = [String: UsernameGenerationOptions]()
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
        pinKeyEncryptedUserKeyValue[userId] = nil
    }

    func deleteAccount() async throws {
        accounts?.removeAll(where: { account in
            account == activeAccount
        })
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

    func getApproveLoginRequests(userId: String?) async throws -> Bool {
        let userId = try unwrapUserId(userId)
        return approveLoginRequestsByUserId[userId] ?? false
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

    func getEnvironmentUrls(userId: String?) async throws -> EnvironmentUrlData? {
        let userId = try unwrapUserId(userId)
        return environmentUrls[userId]
    }

    func getLastActiveTime(userId: String?) async throws -> Date? {
        let userId = try unwrapUserId(userId)
        return lastActiveTime[userId]
    }

    func getLoginRequest() async -> LoginRequestNotification? {
        loginRequest
    }

    func getMasterPasswordHash(userId: String?) async throws -> String? {
        let userId = try unwrapUserId(userId)
        return masterPasswordHashes[userId]
    }

    func getNotificationsLastRegistrationDate(userId: String?) async throws -> Date? {
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

    func getUsernameGenerationOptions(userId: String?) async throws -> UsernameGenerationOptions? {
        let userId = try unwrapUserId(userId)
        return usernameGenerationOptions[userId]
    }

    func getVaultTimeout(userId: String?) async throws -> SessionTimeoutValue {
        let userId = try unwrapUserId(userId)
        return vaultTimeout[userId] ?? .immediately
    }

    func logoutAccount(userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        accountsLoggedOut.append(userId)
    }

    func pinKeyEncryptedUserKey(userId: String?) async throws -> String? {
        let userId = try unwrapUserId(userId)
        return pinKeyEncryptedUserKeyValue[userId] ?? nil
    }

    func pinProtectedUserKey(userId: String?) async throws -> String? {
        let userId = try unwrapUserId(userId)
        return pinProtectedUserKeyValue[userId] ?? nil
    }

    func setAccountEncryptionKeys(_ encryptionKeys: AccountEncryptionKeys, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        accountEncryptionKeys[userId] = encryptionKeys
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

    func setAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        self.allowSyncOnRefresh[userId] = allowSyncOnRefresh
    }

    func setApproveLoginRequests(_ approveLoginRequests: Bool, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        approveLoginRequestsByUserId[userId] = approveLoginRequests
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

    func setIsAuthenticated() {
        activeAccount = .fixture()
        accountEncryptionKeys["1"] = .init(encryptedPrivateKey: "", encryptedUserKey: "")
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

    func setNotificationsLastRegistrationDate(_ date: Date?, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        notificationsLastRegistrationDates[userId] = date
    }

    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions?, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        passwordGenerationOptions[userId] = options
    }

    func setPinKeys(
        pinKeyEncryptedUserKey: String,
        pinProtectedUserKey: String,
        requirePasswordAfterRestart: Bool
    ) async throws {
        let userId = try unwrapUserId(nil)
        pinProtectedUserKeyValue[userId] = pinProtectedUserKey
        pinKeyEncryptedUserKeyValue[userId] = pinKeyEncryptedUserKey

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

    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions?, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        usernameGenerationOptions[userId] = options
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

    func connectToWatchPublisher() async -> AnyPublisher<Bool, Never> {
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
