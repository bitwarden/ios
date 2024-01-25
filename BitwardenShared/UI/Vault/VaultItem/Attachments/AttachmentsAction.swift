import BitwardenSdk

// MARK: - AttachmentsAction

/// Actions that can be processed by an `AttachmentsProcessor`.
///
enum AttachmentsAction: Equatable {
    /// The choose file button was pressed.
    case chooseFilePressed

    /// The delete button was pressed for an attachment.
    case deletePressed(AttachmentView)

    /// The dismiss button was pressed.
    case dismissPressed

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
