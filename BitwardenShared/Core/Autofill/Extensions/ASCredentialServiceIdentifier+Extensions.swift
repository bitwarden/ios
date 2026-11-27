import AuthenticationServices
import BitwardenKit

public extension ASCredentialServiceIdentifier {
    /// Returns the identifier normalized to a URI string.
    var normalizedURI: String {
        switch type {
        case .domain: "https://" + identifier
        case .app, .URL: identifier
        @unknown default: identifier
        }
    }
}

extension ASCredentialServiceIdentifier {
    // MARK: Methods

    /// Returns whether a URI, such as the URI of a save-password request, refers to the service
    /// this identifier was registered for.
    ///
    /// - A `.domain` identifier matches a web URI with the same host, regardless of its scheme,
    ///   port, or path.
    /// - A `.URL` identifier matches the same URI, ignoring surrounding whitespace and compared with a
    ///   default `https://` scheme and without a trailing slash, so `www.example.com` matches
    ///   `https://www.example.com/`.
    /// - Any other identifier matches the same identifier string.
    ///
    /// - Parameter uri: The URI to compare with this identifier.
    /// - Returns: `true` if the URI refers to this identifier's service.
    ///
    func matches(uri: String) -> Bool {
        switch type {
        case .domain:
            uri.httpHost == identifier.lowercased()
        case .URL:
            identifier.httpsNormalized() == uri.trimmingCharacters(in: .whitespacesAndNewlines).httpsNormalized()
        case .app:
            identifier == uri
        @unknown default:
            identifier == uri
        }
    }
}
