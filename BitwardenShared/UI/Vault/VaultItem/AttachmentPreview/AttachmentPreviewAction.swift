import BitwardenKit

// MARK: - AttachmentPreviewAction

/// Actions that can be processed by an `AttachmentPreviewProcessor`.
///
enum AttachmentPreviewAction: Equatable, Sendable {
    /// The dismiss button was pressed.
    case dismissPressed

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
