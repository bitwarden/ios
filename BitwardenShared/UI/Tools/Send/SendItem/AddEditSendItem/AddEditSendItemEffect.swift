// MARK: - AddEditSendItemEffect

/// Effects that can be processed by a `AddEditSendItemProcessor`.
///
enum AddEditSendItemEffect: Equatable {
    /// The copy link button was pressed.
    case copyLinkPressed

    /// The delete button was pressed.
    case deletePressed

    /// The remove password button was pressed.
    case removePassword

    /// The save buton was pressed.
    case savePressed

    /// The share link button was pressed.
    case shareLinkPressed
}
