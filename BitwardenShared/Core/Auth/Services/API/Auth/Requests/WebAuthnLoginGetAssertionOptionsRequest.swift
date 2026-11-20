import Networking

// MARK: - WebAuthnLoginGetAssertionOptionsRequest

/// Request to retrieve the options to log in with a WebAuthn login credential. This is an
/// unauthenticated request to the identity service.
struct WebAuthnLoginGetAssertionOptionsRequest: Request {
    typealias Response = WebAuthnLoginAssertionOptionsResponse

    // MARK: Properties

    /// The HTTP method for this request.
    var method: HTTPMethod { .get }

    /// The URL path for this request.
    var path: String { "/accounts/webauthn/assertion-options" }
}
