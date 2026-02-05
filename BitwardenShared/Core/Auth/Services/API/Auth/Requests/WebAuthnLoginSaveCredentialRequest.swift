import Networking

// MARK: - WebAuthnLoginSaveCredentialRequest

/// Request to store a new WebAuthn credential.
struct WebAuthnLoginSaveCredentialRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The body of the request.
    var body: WebAuthnLoginSaveCredentialRequestModel? { requestModel }

    /// The HTTP method for this request.
    var method: HTTPMethod { .post }

    /// The URL path for this request.
    var path: String { "/webauthn" }

    /// The request details to include in the body of the request.
    let requestModel: WebAuthnLoginSaveCredentialRequestModel
}
