// MARK: SendListAction

/// Actions that can be processed by a `SendListProcessor`.
///
enum SendListAction: Equatable {
    /// The add item button was pressed.
    case addItemPressed

    /// The info button was pressed.
    case infoButtonPressed

    /// The text in the search bar was changed.
    case searchTextChanged(String)

    /// A wrapped `SendListItemRowAction`.
    case sendListItemRow(SendListItemRowAction)
}
