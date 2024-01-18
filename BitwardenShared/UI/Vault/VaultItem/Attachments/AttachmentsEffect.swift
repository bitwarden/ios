// MARK: - AttachmentsEffect

/// Effects that can be processed by an `AttachmentsProcessor`.
///
enum AttachmentsEffect {
    /// Load the user's premium status.
    case loadPremiumStatus

    /// Save the attachments.
    case save
}
