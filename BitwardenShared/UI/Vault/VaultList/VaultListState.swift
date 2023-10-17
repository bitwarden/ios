// MARK: - VaultListState

/// An object that defines the current state of a `VaultListView`.
///
struct VaultListState: Equatable {
    /// The user's initials.
    var userInitials: String = ""

    /// The text that the user is currently searching for.
    var searchText: String = ""
}
