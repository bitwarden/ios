// MARK: - VaultListState

/// An object that defines the current state of a `VaultListView`.
///
struct VaultListState: Equatable {
    /// The user's initials.
    var userInitials: String = ""

    var searchText: String = ""
}
