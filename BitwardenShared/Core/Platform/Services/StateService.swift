import Combine
import Foundation

// swiftlint:disable file_length

// MARK: - StateService

/// A protocol for a `StateService` which manages the state of the accounts in the app.
///
protocol StateService: AnyObject {
    /// The language option currently selected for the app.
    var appLanguage: LanguageOption { get set }

    /// The organization identifier being remembered on the single-sign on screen.
    var rememberedOrgIdentifier: String? { get set }

    /// Adds a new account to the app's state after a successful login.
    ///
    /// - Parameter account: The `Account` to add.
    ///
    func addAccount(_ account: Account) async

    /// Clears the pins stored on device and in memory.
    ///
    func clearPins() async throws

    /// Deletes the current active account.
    ///
    func deleteAccount() async throws

    /// Gets the account encryptions keys for an account.
    ///
    /// - Parameter userId: The user ID of the account. Defaults to the active account if `nil`.
    /// - Returns: The account encryption keys.
    ///
    func getAccountEncryptionKeys(userId: String?) async throws -> AccountEncryptionKeys

    /// Gets all accounts.
    ///
    /// - Returns: The known user accounts.
    ///
    func getAccounts() async throws -> [Account]

    /// Gets the account id or the active account id for a possible id.
    /// - Parameter userId: The possible user Id of an account
    /// - Returns: The user account id or the active id
    ///
    func getAccountIdOrActiveId(userId: String?) async throws -> String

    /// Gets the active account.
    ///
    /// - Returns: The active user account.
    ///
    func getActiveAccount() async throws -> Account

    /// Gets the active account id.
    ///
    /// - Returns: The active user account id.
    ///
    func getActiveAccountId() async throws -> String

    /// Gets the allow sync on refresh value for an account.
    ///
    /// - Parameter userId: The user ID of the account. Defaults to the active account if `nil`.
    /// - Returns: The allow sync on refresh value.
    ///
    func getAllowSyncOnRefresh(userId: String?) async throws -> Bool

    /// Gets whether the user has decided to allow the device to approve login requests.
    ///
    /// - Parameter userId: The user ID associated with the setting. Defaults to the active account if `nil`.
    ///
    /// - Returns: Whether the user has decided to allow the device to approve login requests.
    ///
    func getApproveLoginRequests(userId: String?) async throws -> Bool

    /// Get the app theme.
    ///
    /// - Returns: The app theme.
    ///
    func getAppTheme() async -> AppTheme

    /// Get the active user's Biometric Authentication Preference.
    ///
    /// - Returns: A `Bool` indicating the user's preference for using biometric authentication.
    ///     If `true`, the device should attempt biometric authentication for authorization events.
    ///     If `false`, the device should not attempt biometric authentication for authorization events.
    ///
    func getBiometricAuthenticationEnabled() async throws -> Bool

    /// Gets the clear clipboard value for an account.
    ///
    /// - Parameter userId: The user ID associated with the clear clipboard value. Defaults to the active
    ///   account if `nil`
    /// - Returns: The time after which the clipboard should clear.
    ///
    func getClearClipboardValue(userId: String?) async throws -> ClearClipboardValue

    /// Gets the connect to watch value for an account.
    ///
    /// - Parameter userId: The user ID associated with the connect to watch value. Defaults to the active
    ///   account if `nil`
    /// - Returns: Whether to connect to the watch app.
    ///
    func getConnectToWatch(userId: String?) async throws -> Bool

    /// Gets the default URI match type value for an account.
    ///
    /// - Parameter userId: The user ID of the account. Defaults to the active account if `nil`.
    /// - Returns: The default URI match type value.
    ///
    func getDefaultUriMatchType(userId: String?) async throws -> UriMatchType

    /// Gets the disable auto-copy TOTP value for an account.
    ///
    /// - Parameter userId: The user ID of the account. Defaults to the active account if `nil`.
    /// - Returns: The disable auto-copy TOTP value.
    ///
    func getDisableAutoTotpCopy(userId: String?) async throws -> Bool

    /// Gets the environment URLs for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the environment URLs.
    /// - Returns: The user's environment URLs.
    ///
    func getEnvironmentUrls(userId: String?) async throws -> EnvironmentUrlData?

    /// The last value of the connect to watch setting, ignoring the user id. Used for
    /// sending the status to the watch if the user is logged out.
    ///
    /// - Returns: The last known value of the `connectToWatch` setting.
    ///
    func getLastUserShouldConnectToWatch() async -> Bool

    /// Gets the master password hash for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the master password hash.
    /// - Returns: The user's master password hash.
    ///
    func getMasterPasswordHash(userId: String?) async throws -> String?

    /// Gets the password generation options for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the password generation options.
    /// - Returns: The password generation options for the user ID.
    ///
    func getPasswordGenerationOptions(userId: String?) async throws -> PasswordGenerationOptions?

    /// Gets the environment URLs used by the app prior to the user authenticating.
    ///
    /// - Returns: The environment URLs used prior to user authentication.
    ///
    func getPreAuthEnvironmentUrls() async -> EnvironmentUrlData?

    /// Get whether to show the website icons.
    ///
    /// - Returns: Whether to show the website icons.
    ///
    func getShowWebIcons() async -> Bool

    /// Gets the BiometricIntegrityState for the active user.
    ///
    /// - Returns: An optional base64 string encoding of the BiometricIntegrityState `Data` as last stored for the user.
    ///
    func getBiometricIntegrityState() async throws -> String?

    /// Get the two-factor token (non-nil if the user selected the "remember me" option).
    ///
    /// - Parameter email: The user's email address.
    /// - Returns: The two-factor token.
    ///
    func getTwoFactorToken(email: String) async -> String?

    /// Gets the number of unsuccessful attempts to unlock the vault for a user ID.
    ///
    /// - Parameter userId: The optional user ID associated with the unsuccessful unlock attempts,
    /// if `nil` defaults to currently active user.
    /// - Returns: The number of unsuccessful attempts to unlock the vault.
    ///
    func getUnsuccessfulUnlockAttempts(userId: String?) async throws -> Int

    /// Gets the username generation options for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the username generation options.
    /// - Returns: The username generation options for the user ID.
    ///
    func getUsernameGenerationOptions(userId: String?) async throws -> UsernameGenerationOptions?

    /// Logs the user out of an account.
    ///
    /// - Parameter userId: The user ID of the account to log out of. Defaults to the active
    ///   account if `nil`.
    ///
    func logoutAccount(userId: String?) async throws

    /// The user's pin key encrypted user key.
    ///
    /// - Parameter userId: The user ID associated with the pin key encrypted user key.
    /// - Returns: The user's pin key encrypted user key.
    ///
    func pinKeyEncryptedUserKey(userId: String?) async throws -> String?

    /// The pin protected user key.
    ///
    /// - Parameter userId: The user ID associated with the pin protected user key.
    /// - Returns: The user's pin protected user key.
    ///
    func pinProtectedUserKey(userId: String?) async throws -> String?

    /// Sets the account encryption keys for an account.
    ///
    /// - Parameters:
    ///   - encryptionKeys:  The account encryption keys.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setAccountEncryptionKeys(_ encryptionKeys: AccountEncryptionKeys, userId: String?) async throws

    /// Sets the active account.
    ///
    /// - Parameter userId: The user Id of the account to set as active.
    ///
    func setActiveAccount(userId: String) async throws

    /// Sets the allow sync on refresh value for an account.
    ///
    /// - Parameters:
    ///   - allowSyncOnRefresh: Whether to allow sync on refresh.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool, userId: String?) async throws

    /// Sets whether the user has decided to allow the device to approve login requests.
    ///
    /// - Parameters:
    ///   - approveLoginRequests: Whether the user has decided to allow the device to approve login requests.
    ///   - userId: The user ID associated with the setting. Defaults to the active account if `nil`.
    ///
    func setApproveLoginRequests(_ approveLoginRequests: Bool, userId: String?) async throws

    /// Sets the app theme.
    ///
    /// - Parameter appTheme: The new app theme.
    ///
    func setAppTheme(_ appTheme: AppTheme) async

    /// Sets the user's Biometric Authentication Preference.
    ///
    /// - Parameter isEnabled: A `Bool` indicating the user's preference for using biometric authentication.
    ///     If `true`, the device should attempt biometric authentication for authorization events.
    ///     If `false`, the device should not attempt biometric authentication for authorization events.
    ///
    func setBiometricAuthenticationEnabled(_ isEnabled: Bool?) async throws

    /// Sets the BiometricIntegrityState for the active user.
    ///
    /// - Parameter base64State: A base64 string encoding of the BiometricIntegrityState `Data`.
    ///
    func setBiometricIntegrityState(_ base64State: String?) async throws

    /// Sets the clear clipboard value for an account.
    ///
    /// - Parameters:
    ///   - clearClipboardValue: The time after which to clear the clipboard.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String?) async throws

    /// Sets the connect to watch value for an account.
    ///
    /// - Parameters:
    ///   - connectToWatch: Whether to connect to the watch app.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setConnectToWatch(_ connectToWatch: Bool, userId: String?) async throws

    /// Sets the default URI match type value for an account.
    ///
    /// - Parameters:
    ///   - defaultUriMatchType: The default URI match type.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setDefaultUriMatchType(_ defaultUriMatchType: UriMatchType?, userId: String?) async throws

    /// Sets the disable auto-copy TOTP value for an account.
    ///
    /// - Parameters:
    ///   - disableAutoTotpCopy: Whether the TOTP for a cipher should be auto-copied.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setDisableAutoTotpCopy(_ disableAutoTotpCopy: Bool, userId: String?) async throws

    /// Sets the time of the last sync for a user ID.
    ///
    /// - Parameters:
    ///   - date: The time of the last sync.
    ///   - userId: The user ID associated with the last sync time.
    ///
    func setLastSyncTime(_ date: Date?, userId: String?) async throws

    /// Sets the master password hash for a user ID.
    ///
    /// - Parameters:
    ///   - hash: The user's master password hash.
    ///   - userId: The user ID associated with the master password hash.
    ///
    func setMasterPasswordHash(_ hash: String?, userId: String?) async throws

    /// Sets the password generation options for a user ID.
    ///
    /// - Parameters:
    ///   - options: The user's password generation options.
    ///   - userId: The user ID associated with the password generation options.
    ///
    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions?, userId: String?) async throws

    /// Set's the pin keys.
    ///
    /// - Parameters:
    ///   - pinKeyEncryptedUserKey: The user's encrypted pin.
    ///   - pinProtectedUserKey: The user's pin protected user key.
    ///   - requirePasswordAfterRestart: Whether to require password after app restart.
    ///
    func setPinKeys(
        pinKeyEncryptedUserKey: String,
        pinProtectedUserKey: String,
        requirePasswordAfterRestart: Bool
    ) async throws

    /// Sets the pin protected user key to memory.
    ///
    /// - Parameter pin: The user's pin.
    ///
    func setPinProtectedUserKeyToMemory(_ pin: String) async throws

    /// Sets the environment URLs used prior to user authentication.
    ///
    /// - Parameter urls: The environment URLs used prior to user authentication.
    ///
    func setPreAuthEnvironmentUrls(_ urls: EnvironmentUrlData) async

    /// Set whether to show the website icons.
    ///
    /// - Parameter showWebIcons: Whether to show the website icons.
    ///
    func setShowWebIcons(_ showWebIcons: Bool) async

    /// Sets a new access and refresh token for an account.
    ///
    /// - Parameters:
    ///   - accessToken: The account's updated access token.
    ///   - refreshToken: The account's updated refresh token.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setTokens(accessToken: String, refreshToken: String, userId: String?) async throws

    /// Sets the user's two-factor token.
    ///
    /// - Parameters:
    ///   - token: The two-factor token.
    ///   - email: The user's email address.
    ///
    func setTwoFactorToken(_ token: String?, email: String) async

    /// Sets the number of unsuccessful attempts to unlock the vault for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the unsuccessful unlock attempts.
    /// if `nil` defaults to currently active user.
    ///
    func setUnsuccessfulUnlockAttempts(_ attempts: Int, userId: String?) async throws

    /// Sets the username generation options for a user ID.
    ///
    /// - Parameters:
    ///   - options: The user's username generation options.
    ///   - userId: The user ID associated with the username generation options.
    ///
    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions?, userId: String?) async throws

    // MARK: Publishers

    /// A publisher for the active account id
    ///
    /// - Returns: The userId `String` of the active account
    ///
    func activeAccountIdPublisher() async -> AnyPublisher<String?, Never>

    /// A publisher for the app theme.
    ///
    /// - Returns: A publisher for the app theme.
    ///
    func appThemePublisher() async -> AnyPublisher<AppTheme, Never>

    /// A publisher for the connect to watch value.
    ///
    /// - Returns: A publisher for the connect to watch value.
    ///
    func connectToWatchPublisher() async -> AnyPublisher<Bool, Never>

    /// A publisher for the last sync time for the active account.
    ///
    /// - Returns: A publisher for the last sync time.
    ///
    func lastSyncTimePublisher() async throws -> AnyPublisher<Date?, Never>

    /// A publisher for whether or not to show the web icons.
    ///
    /// - Returns: A publisher for whether or not to show the web icons.
    ///
    func showWebIconsPublisher() async -> AnyPublisher<Bool, Never>
}

extension StateService {
    /// Gets the account encryptions keys for the active account.
    ///
    /// - Returns: The account encryption keys.
    ///
    func getAccountEncryptionKeys() async throws -> AccountEncryptionKeys {
        try await getAccountEncryptionKeys(userId: nil)
    }

    /// Gets the allow sync on refresh value for the active account.
    ///
    /// - Returns: The allow sync on refresh value.
    ///
    func getAllowSyncOnRefresh() async throws -> Bool {
        try await getAllowSyncOnRefresh(userId: nil)
    }

    /// Gets whether the current user has decided to allow the device to approve login requests.
    ///
    /// - Parameter userId: The user ID associated with the setting. Defaults to the active account if `nil`.
    ///
    /// - Returns: Whether the current user has decided to allow the device to approve login requests.
    ///
    func getApproveLoginRequests() async throws -> Bool {
        try await getApproveLoginRequests(userId: nil)
    }

    /// Gets the clear clipboard value for the active account.
    ///
    /// - Returns: The clear clipboard value.
    ///
    func getClearClipboardValue() async throws -> ClearClipboardValue {
        try await getClearClipboardValue(userId: nil)
    }

    /// Gets the connect to watch value for the active account.
    ///
    /// - Returns: Whether to connect to the watch app.
    ///
    func getConnectToWatch() async throws -> Bool {
        try await getConnectToWatch(userId: nil)
    }

    /// Gets the default URI match type value for the active account.
    ///
    /// - Returns: The default URI match type value.
    ///
    func getDefaultUriMatchType() async throws -> UriMatchType {
        try await getDefaultUriMatchType(userId: nil)
    }

    /// Gets the disable auto-copy TOTP value for the active account.
    ///
    /// - Returns: The disable auto-copy TOTP value.
    ///
    func getDisableAutoTotpCopy() async throws -> Bool {
        try await getDisableAutoTotpCopy(userId: nil)
    }

    /// Gets the environment URLs for the active account.
    ///
    /// - Returns: The environment URLs for the active account.
    ///
    func getEnvironmentUrls() async throws -> EnvironmentUrlData? {
        try await getEnvironmentUrls(userId: nil)
    }

    /// Gets the master password hash for the active account.
    ///
    /// - Returns: The user's master password hash.
    ///
    func getMasterPasswordHash() async throws -> String? {
        try await getMasterPasswordHash(userId: nil)
    }

    /// Gets the password generation options for the active account.
    ///
    /// - Returns: The password generation options for the user ID.
    ///
    func getPasswordGenerationOptions() async throws -> PasswordGenerationOptions? {
        try await getPasswordGenerationOptions(userId: nil)
    }

    /// Sets the number of unsuccessful attempts to unlock the vault for the active account.
    ///
    /// - Returns: The number of unsuccessful unlock attempts for the active account.
    ///
    func getUnsuccessfulUnlockAttempts() async -> Int {
        if let attempts = try? await getUnsuccessfulUnlockAttempts(userId: nil) {
            return attempts
        }
        return 0
    }

    /// Gets the username generation options for the active account.
    ///
    /// - Returns: The username generation options for the user ID.
    ///
    func getUsernameGenerationOptions() async throws -> UsernameGenerationOptions? {
        try await getUsernameGenerationOptions(userId: nil)
    }

    /// Logs the user out of the active account.
    ///
    func logoutAccount() async throws {
        try await logoutAccount(userId: nil)
    }

    /// The user's pin protected user key.
    ///
    /// - Returns: The pin protected user key.
    ///
    func pinKeyEncryptedUserKey() async throws -> String? {
        try await pinKeyEncryptedUserKey(userId: nil)
    }

    /// The pin protected user key.
    ///
    /// - Returns: The pin protected user key.
    ///
    func pinProtectedUserKey() async throws -> String? {
        try await pinProtectedUserKey(userId: nil)
    }

    /// Sets the account encryption keys for the active account.
    ///
    /// - Parameter encryptionKeys: The account encryption keys.
    ///
    func setAccountEncryptionKeys(_ encryptionKeys: AccountEncryptionKeys) async throws {
        try await setAccountEncryptionKeys(encryptionKeys, userId: nil)
    }

    /// Sets the allow sync on refresh value for the active account.
    ///
    /// - Parameter allowSyncOnRefresh: The allow sync on refresh value.
    ///
    func setAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool) async throws {
        try await setAllowSyncOnRefresh(allowSyncOnRefresh, userId: nil)
    }

    /// Sets whether the current user has decided to allow the device to approve login requests.
    ///
    /// - Parameter approveLoginRequests: Whether the user has decided to allow the device to approve login requests.
    ///
    func setApproveLoginRequests(_ approveLoginRequests: Bool) async throws {
        try await setApproveLoginRequests(approveLoginRequests, userId: nil)
    }

    /// Sets the clear clipboard value for the active account.
    ///
    /// - Parameter clearClipboardValue: The time after which to clear the clipboard.
    ///
    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?) async throws {
        try await setClearClipboardValue(clearClipboardValue, userId: nil)
    }

    /// Sets the connect to watch value for the active account.
    ///
    /// - Parameter connectToWatch: Whether to connect to the watch app.
    ///
    func setConnectToWatch(_ connectToWatch: Bool) async throws {
        try await setConnectToWatch(connectToWatch, userId: nil)
    }

    /// Sets the default URI match type value the active account.
    ///
    /// - Parameter defaultUriMatchType: The default URI match type.
    ///
    func setDefaultUriMatchType(_ defaultUriMatchType: UriMatchType?) async throws {
        try await setDefaultUriMatchType(defaultUriMatchType, userId: nil)
    }

    /// Sets the disable auto-copy TOTP value for an account.
    ///
    /// - Parameter disableAutoTotpCopy: Whether the TOTP for a cipher should be auto-copied.
    ///
    func setDisableAutoTotpCopy(_ disableAutoTotpCopy: Bool) async throws {
        try await setDisableAutoTotpCopy(disableAutoTotpCopy, userId: nil)
    }

    /// Sets the time of the last sync for a user ID.
    ///
    /// - Parameter date: The time of the last sync (as the number of seconds since the Unix epoch).]
    ///
    func setLastSyncTime(_ date: Date?) async throws {
        try await setLastSyncTime(date, userId: nil)
    }

    /// Sets the master password hash for the active account.
    ///
    /// - Parameter hash: The user's master password hash.
    ///
    func setMasterPasswordHash(_ hash: String?) async throws {
        try await setMasterPasswordHash(hash, userId: nil)
    }

    /// Sets the password generation options for the active account.
    ///
    /// - Parameter options: The user's password generation options.
    ///
    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions?) async throws {
        try await setPasswordGenerationOptions(options, userId: nil)
    }

    /// Sets a new access and refresh token for the active account.
    ///
    /// - Parameters:
    ///   - accessToken: The account's updated access token.
    ///   - refreshToken: The account's updated refresh token.
    ///
    func setTokens(accessToken: String, refreshToken: String) async throws {
        try await setTokens(accessToken: accessToken, refreshToken: refreshToken, userId: nil)
    }

    /// Sets the number of unsuccessful attempts to unlock the vault for the active account.
    ///
    /// - Parameter attempts: The number of unsuccessful unlock attempts.
    ///
    func setUnsuccessfulUnlockAttempts(_ attempts: Int) async {
        try? await setUnsuccessfulUnlockAttempts(attempts, userId: nil)
    }

    /// Sets the username generation options for the active account.
    ///
    /// - Parameter options: The user's username generation options.
    ///
    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions?) async throws {
        try await setUsernameGenerationOptions(options, userId: nil)
    }
}

// MARK: - StateServiceError

/// The errors thrown from a `StateService`.
///
enum StateServiceError: Error {
    /// There are no known accounts.
    case noAccounts

    /// There isn't an active account.
    case noActiveAccount

    /// There is no pin key encrypted user key.
    case noPinKeyEncryptedUserKey

    /// There is no pin protected user key.
    case noPinProtectedUserKey
}

// MARK: - DefaultStateService

/// A default implementation of `StateService`.
///
actor DefaultStateService: StateService { // swiftlint:disable:this type_body_length
    // MARK: Properties

    /// The language option currently selected for the app.
    nonisolated var appLanguage: LanguageOption {
        get { LanguageOption(appSettingsStore.appLocale) }
        set { appSettingsStore.appLocale = newValue.value }
    }

    /// The organization identifier being remembered on the single-sign on screen.
    nonisolated var rememberedOrgIdentifier: String? {
        get { appSettingsStore.rememberedOrgIdentifier }
        set { appSettingsStore.rememberedOrgIdentifier = newValue }
    }

    // MARK: Private Properties

    /// The data stored in memory.
    var accountVolatileData: [String: AccountVolatileData] = [:]

    /// The service that persists app settings.
    let appSettingsStore: AppSettingsStore

    /// A subject containing the app theme.
    private var appThemeSubject: CurrentValueSubject<AppTheme, Never>

    /// A subject containing the connect to watch value.
    private var connectToWatchByUserIdSubject = CurrentValueSubject<[String: Bool], Never>([:])

    /// The data store that handles performing data requests.
    private let dataStore: DataStore

    /// A subject containing the last sync time mapped to user ID.
    private var lastSyncTimeByUserIdSubject = CurrentValueSubject<[String: Date], Never>([:])

    /// A subject containing whether to show the website icons.
    private var showWebIconsSubject: CurrentValueSubject<Bool, Never>

    // MARK: Initialization

    /// Initialize a `DefaultStateService`.
    ///
    /// - Parameters:
    ///   - appSettingsStore: The service that persists app settings.
    ///   - dataStore: The data store that handles performing data requests.
    ///
    init(appSettingsStore: AppSettingsStore, dataStore: DataStore) {
        self.appSettingsStore = appSettingsStore
        self.dataStore = dataStore

        appThemeSubject = CurrentValueSubject(AppTheme(appSettingsStore.appTheme))
        showWebIconsSubject = CurrentValueSubject(!appSettingsStore.disableWebIcons)
    }

    // MARK: Methods

    func addAccount(_ account: Account) async {
        var state = appSettingsStore.state ?? State()
        defer { appSettingsStore.state = state }

        state.accounts[account.profile.userId] = account
        state.activeUserId = account.profile.userId
    }

    func clearPins() async throws {
        let userId = try getActiveAccountUserId()
        accountVolatileData.removeValue(forKey: userId)
        appSettingsStore.setPinProtectedUserKey(key: nil, userId: userId)
        appSettingsStore.setPinKeyEncryptedUserKey(key: nil, userId: userId)
    }

    func deleteAccount() async throws {
        try await logoutAccount()
    }

    func getAccountEncryptionKeys(userId: String?) async throws -> AccountEncryptionKeys {
        let userId = try userId ?? getActiveAccountUserId()
        guard let encryptedPrivateKey = appSettingsStore.encryptedPrivateKey(userId: userId),
              let encryptedUserKey = appSettingsStore.encryptedUserKey(userId: userId)
        else {
            throw StateServiceError.noActiveAccount
        }
        return AccountEncryptionKeys(
            encryptedPrivateKey: encryptedPrivateKey,
            encryptedUserKey: encryptedUserKey
        )
    }

    func getAccountIdOrActiveId(userId: String?) throws -> String {
        guard let accounts = appSettingsStore.state?.accounts else {
            throw StateServiceError.noAccounts
        }
        if let userId {
            guard accounts.contains(where: { $0.value.profile.userId == userId }) else {
                throw StateServiceError.noAccounts
            }
            return userId
        }
        return try getActiveAccountId()
    }

    func getActiveAccountId() throws -> String {
        try getActiveAccount().profile.userId
    }

    func getAccounts() throws -> [Account] {
        guard let accounts = appSettingsStore.state?.accounts else {
            throw StateServiceError.noAccounts
        }
        return Array(accounts.values)
    }

    func getActiveAccount() throws -> Account {
        guard let activeAccount = appSettingsStore.state?.activeAccount else {
            throw StateServiceError.noActiveAccount
        }
        return activeAccount
    }

    func getAllowSyncOnRefresh(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.allowSyncOnRefresh(userId: userId)
    }

    func getApproveLoginRequests(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.approveLoginRequests(userId: userId)
    }

    func getAppTheme() async -> AppTheme {
        AppTheme(appSettingsStore.appTheme)
    }

    func getClearClipboardValue(userId: String?) async throws -> ClearClipboardValue {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.clearClipboardValue(userId: userId)
    }

    func getConnectToWatch(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.connectToWatch(userId: userId)
    }

    func getDefaultUriMatchType(userId: String?) async throws -> UriMatchType {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.defaultUriMatchType(userId: userId) ?? .domain
    }

    func getDisableAutoTotpCopy(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.disableAutoTotpCopy(userId: userId)
    }

    func getEnvironmentUrls(userId: String?) async throws -> EnvironmentUrlData? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.state?.accounts[userId]?.settings.environmentUrls
    }

    func getLastUserShouldConnectToWatch() async -> Bool {
        appSettingsStore.lastUserShouldConnectToWatch
    }

    func getMasterPasswordHash(userId: String?) async throws -> String? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.masterPasswordHash(userId: userId)
    }

    func getPasswordGenerationOptions(userId: String?) async throws -> PasswordGenerationOptions? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.passwordGenerationOptions(userId: userId)
    }

    func getPreAuthEnvironmentUrls() async -> EnvironmentUrlData? {
        appSettingsStore.preAuthEnvironmentUrls
    }

    func getShowWebIcons() async -> Bool {
        !appSettingsStore.disableWebIcons
    }

    func getTwoFactorToken(email: String) async -> String? {
        appSettingsStore.twoFactorToken(email: email)
    }

    func getUnsuccessfulUnlockAttempts(userId: String?) async throws -> Int {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.unsuccessfulUnlockAttempts(userId: userId) ?? 0
    }

    func getUsernameGenerationOptions(userId: String?) async throws -> UsernameGenerationOptions? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.usernameGenerationOptions(userId: userId)
    }

    func logoutAccount(userId: String?) async throws {
        guard var state = appSettingsStore.state else { return }
        defer { appSettingsStore.state = state }

        let knownUserId: String = try userId ?? getActiveAccountUserId()
        state.accounts.removeValue(forKey: knownUserId)
        if state.activeUserId == knownUserId {
            // Find the next account to make the active account.
            state.activeUserId = state.accounts.first?.key
        }

        appSettingsStore.setBiometricAuthenticationEnabled(nil, for: knownUserId)
        appSettingsStore.setBiometricIntegrityState(nil, userId: knownUserId)
        appSettingsStore.setDefaultUriMatchType(nil, userId: knownUserId)
        appSettingsStore.setDisableAutoTotpCopy(nil, userId: knownUserId)
        appSettingsStore.setEncryptedPrivateKey(key: nil, userId: knownUserId)
        appSettingsStore.setEncryptedUserKey(key: nil, userId: knownUserId)
        appSettingsStore.setLastSyncTime(nil, userId: knownUserId)
        appSettingsStore.setMasterPasswordHash(nil, userId: knownUserId)
        appSettingsStore.setPasswordGenerationOptions(nil, userId: knownUserId)

        try await dataStore.deleteDataForUser(userId: knownUserId)
    }

    func pinKeyEncryptedUserKey(userId: String?) async throws -> String? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.pinKeyEncryptedUserKey(userId: userId)
    }

    func pinProtectedUserKey(userId: String?) async throws -> String? {
        let userId = try userId ?? getActiveAccountUserId()
        return accountVolatileData[userId]?.pinProtectedUserKey ?? appSettingsStore.pinProtectedUserKey(userId: userId)
    }

    func setAccountEncryptionKeys(_ encryptionKeys: AccountEncryptionKeys, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setEncryptedPrivateKey(key: encryptionKeys.encryptedPrivateKey, userId: userId)
        appSettingsStore.setEncryptedUserKey(key: encryptionKeys.encryptedUserKey, userId: userId)
    }

    func setActiveAccount(userId: String) async throws {
        guard var state = appSettingsStore.state else { return }
        defer { appSettingsStore.state = state }

        guard state.accounts
            .contains(where: { $0.key == userId }) else { throw StateServiceError.noAccounts }
        state.activeUserId = userId
    }

    func setAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setAllowSyncOnRefresh(allowSyncOnRefresh, userId: userId)
    }

    func setApproveLoginRequests(_ approveLoginRequests: Bool, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setApproveLoginRequests(approveLoginRequests, userId: userId)
    }

    func setAppTheme(_ appTheme: AppTheme) async {
        appSettingsStore.appTheme = appTheme.value
        appThemeSubject.send(appTheme)
    }

    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setClearClipboardValue(clearClipboardValue, userId: userId)
    }

    func setConnectToWatch(_ connectToWatch: Bool, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setConnectToWatch(connectToWatch, userId: userId)
        connectToWatchByUserIdSubject.value[userId] = connectToWatch

        // Save the value of the connect to watch setting independent of the user id,
        // in order to be able to send a status to the watch if the user logs out.
        appSettingsStore.lastUserShouldConnectToWatch = connectToWatch
    }

    func setDefaultUriMatchType(_ defaultUriMatchType: UriMatchType?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setDefaultUriMatchType(defaultUriMatchType, userId: userId)
    }

    func setDisableAutoTotpCopy(_ disableAutoTotpCopy: Bool, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setDisableAutoTotpCopy(disableAutoTotpCopy, userId: userId)
    }

    func setLastSyncTime(_ date: Date?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setLastSyncTime(date, userId: userId)
        lastSyncTimeByUserIdSubject.value[userId] = date
    }

    func setMasterPasswordHash(_ hash: String?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setMasterPasswordHash(hash, userId: userId)
    }

    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setPasswordGenerationOptions(options, userId: userId)
    }

    func setPinKeys(
        pinKeyEncryptedUserKey: String,
        pinProtectedUserKey: String,
        requirePasswordAfterRestart: Bool
    ) async throws {
        if requirePasswordAfterRestart {
            try await setPinProtectedUserKeyToMemory(pinProtectedUserKey)
        } else {
            try appSettingsStore.setPinProtectedUserKey(key: pinProtectedUserKey, userId: getActiveAccountUserId())
        }
        try appSettingsStore.setPinKeyEncryptedUserKey(key: pinKeyEncryptedUserKey, userId: getActiveAccountUserId())
    }

    func setPinProtectedUserKeyToMemory(_ pinProtectedUserKey: String) async throws {
        try accountVolatileData[
            getActiveAccountUserId(),
            default: AccountVolatileData()
        ].pinProtectedUserKey = pinProtectedUserKey
    }

    func setPreAuthEnvironmentUrls(_ urls: EnvironmentUrlData) async {
        appSettingsStore.preAuthEnvironmentUrls = urls
    }

    func setShowWebIcons(_ showWebIcons: Bool) async {
        appSettingsStore.disableWebIcons = !showWebIcons
        showWebIconsSubject.send(showWebIcons)
    }

    func setTokens(accessToken: String, refreshToken: String, userId: String?) async throws {
        guard var state = appSettingsStore.state,
              let userId = userId ?? state.activeUserId
        else {
            throw StateServiceError.noActiveAccount
        }

        state.accounts[userId]?.tokens = Account.AccountTokens(
            accessToken: accessToken,
            refreshToken: refreshToken
        )
        appSettingsStore.state = state
    }

    func setTwoFactorToken(_ token: String?, email: String) async {
        appSettingsStore.setTwoFactorToken(token, email: email)
    }

    func setUnsuccessfulUnlockAttempts(_ attempts: Int, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setUnsuccessfulUnlockAttempts(attempts, userId: userId)
    }

    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setUsernameGenerationOptions(options, userId: userId)
    }

    // MARK: Publishers

    func activeAccountIdPublisher() -> AnyPublisher<String?, Never> {
        appSettingsStore.activeAccountIdPublisher()
    }

    func appThemePublisher() async -> AnyPublisher<AppTheme, Never> {
        appThemeSubject.eraseToAnyPublisher()
    }

    func connectToWatchPublisher() async -> AnyPublisher<Bool, Never> {
        activeAccountIdPublisher().flatMap { userId in
            self.connectToWatchByUserIdSubject.map { values in
                if let userId {
                    // Get the user's setting, if they're logged in.
                    values[userId] ?? self.appSettingsStore.connectToWatch(userId: userId)
                } else {
                    // Otherwise, use the last known value for the previous user.
                    self.appSettingsStore.lastUserShouldConnectToWatch
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func lastSyncTimePublisher() async throws -> AnyPublisher<Date?, Never> {
        let userId = try getActiveAccountUserId()
        if lastSyncTimeByUserIdSubject.value[userId] == nil {
            lastSyncTimeByUserIdSubject.value[userId] = appSettingsStore.lastSyncTime(userId: userId)
        }
        return lastSyncTimeByUserIdSubject.map { $0[userId] }.eraseToAnyPublisher()
    }

    func showWebIconsPublisher() async -> AnyPublisher<Bool, Never> {
        showWebIconsSubject.eraseToAnyPublisher()
    }

    // MARK: Private

    /// Returns the user ID for the active account.
    ///
    /// - Returns: The user ID for the active account.
    ///
    private func getActiveAccountUserId() throws -> String {
        guard let activeUserId = appSettingsStore.state?.activeUserId else {
            throw StateServiceError.noActiveAccount
        }
        return activeUserId
    }
}

// MARK: - AccountVolatileData

/// The data stored in memory.
///
struct AccountVolatileData {
    /// The pin protected user key.
    var pinProtectedUserKey: String = ""
}

// MARK: Biometrics

extension DefaultStateService {
    func getBiometricAuthenticationEnabled() async throws -> Bool {
        let userId = try getActiveAccountUserId()
        return appSettingsStore.isBiometricAuthenticationEnabled(userId: userId)
    }

    func getBiometricIntegrityState() async throws -> String? {
        let userId = try getActiveAccountUserId()
        return appSettingsStore.biometricIntegrityState(userId: userId)
    }

    func setBiometricAuthenticationEnabled(_ isEnabled: Bool?) async throws {
        let userId = try getActiveAccountUserId()
        appSettingsStore.setBiometricAuthenticationEnabled(isEnabled, for: userId)
    }

    func setBiometricIntegrityState(_ base64State: String?) async throws {
        let userId = try getActiveAccountUserId()
        appSettingsStore.setBiometricIntegrityState(base64State, userId: userId)
    }
}
