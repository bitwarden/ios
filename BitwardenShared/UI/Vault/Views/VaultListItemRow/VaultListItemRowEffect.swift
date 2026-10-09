// MARK: - VaultListItemRowEffect

/// Effects that can be performed from a `VaultListItemRowView`.
enum VaultListItemRowEffect: Equatable {
    /// A VoiceOver custom accessibility action for one of the more-options actions was activated.
    case accessibilityMoreOptionsActionPressed(MoreOptionsActionKind)

    /// The more button was pressed.
    case morePressed

    /// The row was pressed to open the item.
    case pressed
}
