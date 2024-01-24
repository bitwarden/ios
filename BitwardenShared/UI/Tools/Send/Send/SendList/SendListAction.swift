// MARK: SendListAction

/// Actions that can be processed by a `SendListProcessor`.
///
enum SendListAction: Equatable {
    /// The add item button was pressed.
    case addItemPressed

    /// Clears the info URL after the web app has been opened.
    case clearInfoUrl

    /// The info button was pressed.
    case infoButtonPressed

    /// The text in the search bar was changed.
    case searchTextChanged(String)

    /// A wrapped `SendListItemRowAction`.
    case sendListItemRow(SendListItemRowAction)

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
