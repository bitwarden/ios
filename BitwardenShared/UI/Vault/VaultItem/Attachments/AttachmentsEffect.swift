// MARK: - AttachmentsEffect

/// Effects that can be processed by an `AttachmentsProcessor`.
///
enum AttachmentsEffect {
    /// The view appeared and the feature flags should be loaded.
    case appeared

    /// Load the user's Premium status.
    case loadPremiumStatus

    /// Save the attachments.
    case save
}
