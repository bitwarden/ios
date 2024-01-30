// MARK: - AddEditSendItemEffect

/// Effects that can be processed by a `AddEditSendItemProcessor`.
///
enum AddEditSendItemEffect: Equatable {
    /// The copy link button was pressed.
    case copyLinkPressed

    /// The delete button was pressed.
    case deletePressed

    /// Any initial data for the view should be loaded.
    case loadData

    /// The remove password button was pressed.
    case removePassword

    /// The save button was pressed.
    case savePressed

    /// The share link button was pressed.
    case shareLinkPressed
}
