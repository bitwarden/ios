// MARK: - AutofillAssistMapping

/// A URL host-based mapping associating a web page with stable page field identifiers
/// for username and password autofill.
///
struct AutofillAssistMapping: Codable, Equatable {
    // MARK: Properties

    /// The stable identifier of the page field to fill with the password.
    let passwordFieldIdentifier: String?

    /// The URL host (e.g. "example.com") this mapping applies to.
    let urlHost: String

    /// The stable identifier of the page field to fill with the username.
    let usernameFieldIdentifier: String?
}
