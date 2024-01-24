// MARK: - ActionExtensionContext

/// A data model containing the details of the processed items within the action extension.
///
struct ActionExtensionContext {
    // MARK: Properties

    /// Whether the extension helper has finished loading the input items. This is used for testing
    /// `ActionExtensionHelper`.
    var didFinishLoadingItem = false

    /// The extracted details of the web page to determine the fields to autofill.
    var pageDetails: PageDetails?

    /// The processed provider type used to determine the action and output of the extension.
    var providerType: String?

    /// The URL of the page or app to determine matching ciphers.
    var urlString: String?
}
