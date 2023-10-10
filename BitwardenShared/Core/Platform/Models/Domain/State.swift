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
}
