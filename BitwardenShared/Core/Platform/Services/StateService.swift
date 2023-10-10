/// A protocol for a `StateService` which manages the state of the accounts in the app.
///
protocol StateService: AnyObject {
    /// Adds a new account to the app's state after a successful login.
    ///
    /// - Parameter account: The `Account` to add.
    ///
    func addAccount(_ account: Account) async

    /// Gets the account encryptions keys for the active account.
    ///
    /// - Returns: The account encryption keys.
    ///
    func getAccountEncryptionKeys() async throws -> AccountEncryptionKeys

    /// Gets the active account.
    ///
    /// - Returns: The active user account.
    ///
    func getActiveAccount() async throws -> Account

    /// Logs the user out of the account with the specified user ID.
    ///
    /// - Parameter userId: The user ID of the account to log out of.
    ///
    func logoutAccount(_ userId: String) async

    /// Sets the account encryption keys for the active account.
    ///
    /// - Parameter encryptionKeys: The account encryption keys.
    ///
    func setAccountEncryptionKeys(_ encryptionKeys: AccountEncryptionKeys) async throws

    /// Sets a new access and refresh token for the active account.
    ///
    /// - Parameters:
    ///   - accessToken: The account's updated access token.
    ///   - refreshToken: The account's updated refresh token.
    ///
    func setTokens(accessToken: String, refreshToken: String) async throws
}

// MARK: - TokenServiceError

/// The errors thrown from a `StateService`.
///
enum StateServiceError: Error {
    /// There isn't an active account.
    case noActiveAccount
}

// MARK: - DefaultStateService

/// A default implementation of `StateService`.
///
actor DefaultStateService: StateService {
    // MARK: Properties

    /// The service that persists app settings.
    let appSettingsStore: AppSettingsStore

    // MARK: Initialization

    /// Initialize a `DefaultStateService`.
    ///
    /// - Parameter appSettingsStore: The service that persists app settings.
    ///
    init(appSettingsStore: AppSettingsStore) {
        self.appSettingsStore = appSettingsStore
    }

    // MARK: Methods

    func addAccount(_ account: Account) async {
        var state = appSettingsStore.state ?? State()
        defer { appSettingsStore.state = state }

        state.accounts[account.profile.userId] = account
        state.activeUserId = account.profile.userId
    }

    func getAccountEncryptionKeys() async throws -> AccountEncryptionKeys {
        let userId = try await getActiveAccountUserId()
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

    func getActiveAccount() async throws -> Account {
        guard let activeAccount = appSettingsStore.state?.activeAccount else {
            throw StateServiceError.noActiveAccount
        }
        return activeAccount
    }

    func logoutAccount(_ userId: String) async {
        guard var state = appSettingsStore.state else { return }
        defer { appSettingsStore.state = state }

        state.accounts.removeValue(forKey: userId)
        if state.activeUserId == userId {
            // Find the next account to make the active account.
            state.activeUserId = state.accounts.first?.key
        }
    }

    func setAccountEncryptionKeys(_ encryptionKeys: AccountEncryptionKeys) async throws {
        let userId = try await getActiveAccountUserId()
        appSettingsStore.setEncryptedPrivateKey(key: encryptionKeys.encryptedPrivateKey, userId: userId)
        appSettingsStore.setEncryptedUserKey(key: encryptionKeys.encryptedUserKey, userId: userId)
    }

    func setTokens(accessToken: String, refreshToken: String) async throws {
        guard var state = appSettingsStore.state,
              let activeUserId = state.activeUserId
        else {
            throw StateServiceError.noActiveAccount
        }

        state.accounts[activeUserId]?.tokens = Account.AccountTokens(
            accessToken: accessToken,
            refreshToken: refreshToken
        )
        appSettingsStore.state = state
    }

    // MARK: Private

    /// Returns the user ID for the active account.
    ///
    /// - Returns: The user ID for the active account.
    ///
    private func getActiveAccountUserId() async throws -> String {
        try await getActiveAccount().profile.userId
    }
}
