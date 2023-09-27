/// Domain model for the app's account state.
///
struct State: Codable, Equatable {
    // MARK: Properties

    /// The list of the accounts on the device, keyed by the user's ID.
    var accounts: [String: Account]

    /// The user ID for the active account.
    var activeUserId: String?

    // MARK: Computed Properties

    /// The active user account.
    var activeAccount: Account? {
        guard let activeUserId else { return nil }
        return accounts[activeUserId]
    }

    // MARK: Initialization

    /// Initialize a `State`.
    ///
    /// - Parameters:
    ///   - accounts: The list of the accounts on the device, keyed by the user's ID.
    ///   - activeUserId: The user ID for the active account.
    ///
    init(accounts: [String: Account] = [:], activeUserId: String? = nil) {
        self.accounts = accounts
        self.activeUserId = activeUserId
    }
}
