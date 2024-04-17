// MARK: - ItemListEffect

/// Effects that can be handled by a `ItemListProcessor`.
enum ItemListEffect: Equatable {
    /// The add item button was pressed.
    case addItemPressed

    /// The vault group view appeared on screen.
    case appeared

    /// The copy code button was pressed.
    ///
    case copyPressed(_ item: ItemListItem)

    /// The refresh control was triggered.
    case refresh

    /// Searches based on the keyword.
    case search(String)

    /// Stream the vault list for the user.
    case streamItemList
}
