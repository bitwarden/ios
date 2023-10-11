// MARK: - VaultListAction

/// Actions that can be processed by a `VaultListProcessor`.
enum VaultListAction: Equatable {
    /// The add item button was pressed.
    case addItemPressed

    /// The profile initials button was pressed.
    case profilePressed

    /// The text in the search bar was changed.
    case searchTextChanged(String)
}
