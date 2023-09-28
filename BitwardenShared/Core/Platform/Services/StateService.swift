/// A protocol for a `StateService` which manages the state of the accounts in the app.
///
protocol StateService: AnyObject {
    /// Adds a new account to the app's state after a successful login.
    ///
    /// - Parameter account: The `Account` to add.
    ///
    func addAccount(_ account: Account) async

    /// Gets the account encryptions keys for the specified user ID.
    ///
    /// - Parameter userId: The user ID used to look up the account encryption keys.
    /// - Returns: The account encryption keys.
    ///
    func getAccountEncryptionKeys(_ userId: String) async -> AccountEncryptionKeys?

    /// Gets the active account.
    ///
    /// - Returns: The active user account.
    ///
    func getActiveAccount() async -> Account?

    /// Logs the user out of the account with the specified user ID.
    ///
    /// - Parameter userId: The user ID of the account to log out of.
    ///
    func logoutAccount(_ userId: String) async

    /// Sets the account encryption keys for the specified user ID.
    ///
    /// - Parameters:
    ///   - encryptionKeys: The account encryption keys.
    ///   - userId: The user ID associated with the account encryption keys.
    ///
    func setAccountEncryptionKeys(_ encryptionKeys: AccountEncryptionKeys, userId: String) async
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

    func getAccountEncryptionKeys(_ userId: String) async -> AccountEncryptionKeys? {
        guard let encryptedPrivateKey = appSettingsStore.encryptedPrivateKey(userId: userId),
              let encryptedUserKey = appSettingsStore.encryptedUserKey(userId: userId)
        else {
            return nil
        }
        return AccountEncryptionKeys(
            encryptedPrivateKey: encryptedPrivateKey,
            encryptedUserKey: encryptedUserKey
        )
    }

    func getActiveAccount() async -> Account? {
        appSettingsStore.state?.activeAccount
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

    func setAccountEncryptionKeys(_ encryptionKeys: AccountEncryptionKeys, userId: String) async {
        appSettingsStore.setEncryptedPrivateKey(key: encryptionKeys.encryptedPrivateKey, userId: userId)
        appSettingsStore.setEncryptedUserKey(key: encryptionKeys.encryptedUserKey, userId: userId)
    }
}
