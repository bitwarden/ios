// MARK: - VaultListState

/// An object that defines the current state of a `VaultListView`.
///
struct VaultListState: Equatable {
    // MARK: Properties

    /// The loading state of the My Vault screen.
    var loadingState: LoadingState<[VaultListSection]> = .loading

    /// The user's current account profile state and alternative accounts.
    var profileSwitcherState = ProfileSwitcherState(accounts: [], activeAccountId: nil, isVisible: false)

    /// An array of results matching the `searchText`.
    var searchResults: [VaultListItem] = []

    /// The text that the user is currently searching for.
    var searchText: String = ""

    /// The user's initials.
    var userInitials: String {
        profileSwitcherState.activeAccountInitials
    }
}
