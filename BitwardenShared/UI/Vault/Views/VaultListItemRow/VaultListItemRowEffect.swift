// MARK: - VaultListItemRowEffect

/// Effects that can be performed from a `VaultListItemRowView`.
enum VaultListItemRowEffect: Equatable {
    /// The more button was pressed.
    case morePressed

    /// The row was pressed to open the item.
    case pressed
}
