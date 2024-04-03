// MARK: - ItemsEffect

/// Effects that can be handled by a `ItemsProcessor`.
enum ItemsEffect: Equatable {
    /// The add item button was pressed.
    case addItemPressed

    /// The vault group view appeared on screen.
    case appeared

    /// The refresh control was triggered.
    case refresh

    /// Stream the vault list for the user.
    case streamVaultList
}
