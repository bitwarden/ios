import Networking

// MARK: - WebAuthnLoginGetCredentialCreationOptionsRequest

/// Request to retrieve options for registering a new WebAuthn credential.
struct WebAuthnLoginGetCredentialCreationOptionsRequest: Request {
    typealias Response = WebAuthnLoginCredentialCreationOptionsResponse

    // MARK: Properties

    /// The body of the request.
    var body: SecretVerificationRequestModel? { requestModel }

    /// The HTTP method for this request.
    var method: HTTPMethod { .post }

    /// The URL path for this request.
    var path: String { "/webauthn/attestation-options" }

    /// The request details to include in the body of the request.
    let requestModel: SecretVerificationRequestModel
}
