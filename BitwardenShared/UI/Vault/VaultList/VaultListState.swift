// MARK: - VaultListState

/// An object that defines the current state of a `VaultListView`.
///
struct VaultListState: Equatable {
    /// The user's current account profile state and alternative accounts.
    var profileSwitcherState = ProfileSwitcherState.empty

    /// The user's initials.
    var userInitials: String {
        profileSwitcherState.currentAccountProfile.userInitials
    }

    /// The sections that are displayed in the My Vault screen.
    var sections: [VaultListSection] = []

    /// The text that the user is currently searching for.
    var searchText: String = ""

    /// An array of results matching the `searchText`.
    var searchResults: [VaultListItem] = []
}
