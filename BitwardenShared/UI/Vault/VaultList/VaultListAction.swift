import BitwardenSdk

// MARK: - VaultListAction

/// Actions that can be processed by a `VaultListProcessor`.
enum VaultListAction: Equatable {
    /// The add item button was pressed.
    case addItemPressed

    /// An item in the vault was pressed.
    case itemPressed(item: VaultListItem)

    /// The more button was pressed on an item in the vault.
    case morePressed(item: VaultListItem)

    /// The profile initials button was pressed.
    case profilePressed

    /// The text in the search bar was changed.
    case searchTextChanged(String)
}
