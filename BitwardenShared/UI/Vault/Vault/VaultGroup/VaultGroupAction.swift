// MARK: - VaultGroupAction

/// Actions that can be processed by a `VaultGroupProcessor`.
enum VaultGroupAction: Equatable {
    /// The add item button was pressed.
    case addItemPressed

    /// An item in the vault group was tapped.
    ///
    /// - Parameter item: The item that was tapped.
    case itemPressed(_ item: VaultListItem)

    /// The more button on an item in the vault group was tapped.
    ///
    /// - Parameter item: The item associated with the more button that was tapped.
    case morePressed(_ item: VaultListItem)

    /// The search bar's text was changed.
    case searchTextChanged(String)

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
