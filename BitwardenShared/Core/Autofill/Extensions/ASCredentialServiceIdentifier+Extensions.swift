import AuthenticationServices

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
