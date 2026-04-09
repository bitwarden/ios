import Networking

// MARK: - WebAuthnLoginGetCredentialAssertionOptionsRequest

/// Request to retrieve options to assert a WebAuthn credential.
struct WebAuthnLoginGetCredentialAssertionOptionsRequest: Request {
    typealias Response = WebAuthnLoginCredentialAssertionOptionsResponse

    // MARK: Properties

    /// The body of the request.
    var body: SecretVerificationRequestModel? { requestModel }

    /// The HTTP method for this request.
    var method: HTTPMethod { .post }

    /// The URL path for this request.
    var path: String { "/webauthn/assertion-options" }

    /// The request details to include in the body of the request.
    let requestModel: SecretVerificationRequestModel
}
