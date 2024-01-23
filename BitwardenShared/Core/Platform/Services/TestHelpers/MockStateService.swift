import Combine
import Foundation

@testable import BitwardenShared

class MockStateService: StateService {
    var accountEncryptionKeys = [String: AccountEncryptionKeys]()
    var accountTokens: Account.AccountTokens?
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
    var getAccountEncryptionKeysError: Error?
    var getBiometricAuthenticationEnabledResult: Result<Void, Error> = .success(())
    var getBiometricIntegrityStateError: Error?
    var lastSyncTimeByUserId = [String: Date]()
    var lastSyncTimeSubject = CurrentValueSubject<Date?, Never>(nil)
    var lastUserShouldConnectToWatch = false
    var masterPasswordHashes = [String: String]()
    var passwordGenerationOptions = [String: PasswordGenerationOptions]()
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
    var vaultTimeout = [String: Int]()

    lazy var activeIdSubject = CurrentValueSubject<String?, Never>(self.activeAccount?.profile.userId)
    lazy var appThemeSubject = CurrentValueSubject<AppTheme, Never>(self.appTheme ?? .default)

    func addAccount(_ account: Account) async {
        accountsAdded.append(account)
        activeAccount = account
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
        let userId = try userId ?? getActiveAccount().profile.userId
        guard let encryptionKeys = accountEncryptionKeys[userId]
        else {
            throw StateServiceError.noActiveAccount
        }
        return encryptionKeys
    }

    func getAccounts() async throws -> [Account] {
        guard let accounts else { throw StateServiceError.noAccounts }
        return accounts
    }

    func getActiveAccount() throws -> Account {
        guard let activeAccount else { throw StateServiceError.noActiveAccount }
        return activeAccount
    }

    func getAccountIdOrActiveId(userId: String?) async throws -> String {
        guard let knownAccounts = accounts else {
            throw StateServiceError.noAccounts
        }
        if let userId {
            guard knownAccounts.contains(where: { $0.profile.userId == userId }) else {
                throw StateServiceError.noAccounts
            }
            return userId
        } else {
            return try await getActiveAccountId()
        }
    }

    func getActiveAccountId() async throws -> String {
        try getActiveAccount().profile.userId
    }

    func getApproveLoginRequests(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccount().profile.userId
        return approveLoginRequestsByUserId[userId] ?? false
    }

    func getAppTheme() async -> AppTheme {
        appTheme ?? .default
    }

    func getAllowSyncOnRefresh(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccount().profile.userId
        return allowSyncOnRefresh[userId] ?? false
    }

    func getClearClipboardValue(userId: String?) async throws -> ClearClipboardValue {
        try clearClipboardResult.get()
        let userId = try userId ?? getActiveAccount().profile.userId
        return clearClipboardValues[userId] ?? .never
    }

    func getConnectToWatch(userId: String?) async throws -> Bool {
        try connectToWatchResult.get()
        let userId = try userId ?? getActiveAccount().profile.userId
        return connectToWatchByUserId[userId] ?? false
    }

    func getDefaultUriMatchType(userId: String?) async throws -> UriMatchType {
        let userId = try userId ?? getActiveAccount().profile.userId
        return defaultUriMatchTypeByUserId[userId] ?? .domain
    }

    func getDisableAutoTotpCopy(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccount().profile.userId
        return disableAutoTotpCopyByUserId[userId] ?? false
    }

    func getEnvironmentUrls(userId: String?) async throws -> EnvironmentUrlData? {
        let userId = try userId ?? getActiveAccount().profile.userId
        return environmentUrls[userId]
    }

    func getLastActiveTime(userId: String?) async throws -> Date? {
        let userId = try userId ?? getActiveAccount().profile.userId
        return lastActiveTime[userId]
    }

    func getMasterPasswordHash(userId: String?) async throws -> String? {
        let userId = try userId ?? getActiveAccount().profile.userId
        return masterPasswordHashes[userId]
    }

    func getPasswordGenerationOptions(userId: String?) async throws -> PasswordGenerationOptions? {
        let userId = try userId ?? getActiveAccount().profile.userId
        return passwordGenerationOptions[userId]
    }

    func getPreAuthEnvironmentUrls() async -> EnvironmentUrlData? {
        preAuthEnvironmentUrls
    }

    func getShowWebIcons() async -> Bool {
        showWebIcons
    }

    func getTimeoutAction(userId: String?) async throws -> SessionTimeoutAction? {
        let userId = try userId ?? getActiveAccount().profile.userId
        return timeoutAction[userId] ?? .lock
    }

    func getTwoFactorToken(email: String) async -> String? {
        twoFactorTokens[email]
    }

    func getUnsuccessfulUnlockAttempts(userId: String?) async throws -> Int {
        let userId = try userId ?? getActiveAccount().profile.userId
        return unsuccessfulUnlockAttempts[userId] ?? 0
    }

    func getUsernameGenerationOptions(userId: String?) async throws -> UsernameGenerationOptions? {
        let userId = try userId ?? getActiveAccount().profile.userId
        return usernameGenerationOptions[userId]
    }

    func getVaultTimeout(userId: String?) async throws -> Int {
        let userId = try userId ?? getActiveAccount().profile.userId
        return vaultTimeout[userId] ?? 0
    }

    func logoutAccount(userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        accountsLoggedOut.append(userId)
    }

    func setAccountEncryptionKeys(_ encryptionKeys: AccountEncryptionKeys, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        accountEncryptionKeys[userId] = encryptionKeys
    }

    func setActiveAccount(userId: String) async throws {
        guard let accounts,
              let match = accounts.first(where: { account in
                  account.profile.userId == userId
              }) else { throw StateServiceError.noAccounts }
        activeAccount = match
    }

    func setAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        self.allowSyncOnRefresh[userId] = allowSyncOnRefresh
    }

    func setApproveLoginRequests(_ approveLoginRequests: Bool, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        approveLoginRequestsByUserId[userId] = approveLoginRequests
    }

    func setAppTheme(_ appTheme: AppTheme) async {
        self.appTheme = appTheme
    }

    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String?) async throws {
        try clearClipboardResult.get()
        let userId = try userId ?? getActiveAccount().profile.userId
        clearClipboardValues[userId] = clearClipboardValue
    }

    func setConnectToWatch(_ connectToWatch: Bool, userId: String?) async throws {
        try connectToWatchResult.get()
        let userId = try userId ?? getActiveAccount().profile.userId
        connectToWatchByUserId[userId] = connectToWatch
    }

    func setDefaultUriMatchType(_ defaultUriMatchType: UriMatchType?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        defaultUriMatchTypeByUserId[userId] = defaultUriMatchType
    }

    func setDisableAutoTotpCopy(_ disableAutoTotpCopy: Bool, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        disableAutoTotpCopyByUserId[userId] = disableAutoTotpCopy
    }

    func setEnvironmentUrls(_ environmentUrls: EnvironmentUrlData, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        self.environmentUrls[userId] = environmentUrls
    }

    func setLastActiveTime(userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        lastActiveTime[userId] = timeProvider.presentTime
    }

    func setLastSyncTime(_ date: Date?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        lastSyncTimeByUserId[userId] = date
    }

    func getLastUserShouldConnectToWatch() async -> Bool {
        lastUserShouldConnectToWatch
    }

    func setMasterPasswordHash(_ hash: String?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        masterPasswordHashes[userId] = hash
    }

    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        passwordGenerationOptions[userId] = options
    }

    func setPreAuthEnvironmentUrls(_ urls: BitwardenShared.EnvironmentUrlData) async {
        preAuthEnvironmentUrls = urls
    }

    func setShowWebIcons(_ showWebIcons: Bool) async {
        self.showWebIcons = showWebIcons
    }

    func setTimeoutAction(action: SessionTimeoutAction, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        timeoutAction[userId] = action
    }

    func setTokens(accessToken: String, refreshToken: String, userId _: String?) async throws {
        accountTokens = Account.AccountTokens(accessToken: accessToken, refreshToken: refreshToken)
    }

    func setTwoFactorToken(_ token: String?, email: String) async {
        twoFactorTokens[email] = token
    }

    func setUnsuccessfulUnlockAttempts(_ attempts: Int, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        unsuccessfulUnlockAttempts[userId] = attempts
    }

    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        usernameGenerationOptions[userId] = options
    }

    func setVaultTimeout(value: Int?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        vaultTimeout[userId] = value
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
}
