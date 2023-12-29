// MARK: - EditCollectionsEffect

/// Effects that can be processed by an `EditCollectionsProcessor`.
///
enum EditCollectionsEffect {
    /// Any options that need to be loaded for a cipher (e.g. collections) should be fetched.
    case fetchCipherOptions

    /// The save button was tapped.
    case save
}
