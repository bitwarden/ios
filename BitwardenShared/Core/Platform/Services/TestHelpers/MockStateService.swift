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
    var appTheme: AppTheme?
    var clearClipboardValues = [String: ClearClipboardValue]()
    var clearClipboardResult: Result<Void, Error> = .success(())
    var dateProvider = MockDateProvider()
    var environmentUrls = [String: EnvironmentUrlData]()
    var lastActiveTime = [String: Date]()
    var lastSyncTimeByUserId = [String: Date]()
    var lastSyncTimeSubject = CurrentValueSubject<Date?, Never>(nil)
    var masterPasswordHashes = [String: String]()
    var passwordGenerationOptions = [String: PasswordGenerationOptions]()
    var preAuthEnvironmentUrls: EnvironmentUrlData?
    var rememberedOrgIdentifier: String?
    var showWebIcons = true
    var showWebIconsSubject = CurrentValueSubject<Bool, Never>(true)
    var timeoutAction = [String: SessionTimeoutAction]()
    var usernameGenerationOptions = [String: UsernameGenerationOptions]()
    var vaultTimeout = [String: Double?]()

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

    func getUsernameGenerationOptions(userId: String?) async throws -> UsernameGenerationOptions? {
        let userId = try userId ?? getActiveAccount().profile.userId
        return usernameGenerationOptions[userId]
    }

    func getVaultTimeout(userId: String?) async throws -> Double? {
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

    func setAppTheme(_ appTheme: AppTheme) async {
        self.appTheme = appTheme
    }

    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String?) async throws {
        try clearClipboardResult.get()
        let userId = try userId ?? getActiveAccount().profile.userId
        clearClipboardValues[userId] = clearClipboardValue
    }

    func setEnvironmentUrls(_ environmentUrls: EnvironmentUrlData, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        self.environmentUrls[userId] = environmentUrls
    }

    func setLastActiveTime(userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        lastActiveTime[userId] = dateProvider.now
    }

    func setLastSyncTime(_ date: Date?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        lastSyncTimeByUserId[userId] = date
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

    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        usernameGenerationOptions[userId] = options
    }

    func setVaultTimeout(value: Double?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        vaultTimeout[userId] = value
    }

    func activeAccountIdPublisher() async -> AsyncPublisher<AnyPublisher<String?, Never>> {
        activeIdSubject.eraseToAnyPublisher().values
    }

    func appThemePublisher() async -> AnyPublisher<AppTheme, Never> {
        appThemeSubject.eraseToAnyPublisher()
    }

    func lastSyncTimePublisher() async throws -> AnyPublisher<Date?, Never> {
        lastSyncTimeSubject.eraseToAnyPublisher()
    }

    func showWebIconsPublisher() async -> AsyncPublisher<AnyPublisher<Bool, Never>> {
        showWebIconsSubject.eraseToAnyPublisher().values
    }
}
