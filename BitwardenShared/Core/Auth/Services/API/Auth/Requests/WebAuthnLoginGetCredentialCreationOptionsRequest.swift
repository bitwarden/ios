import Networking

/// Request to retrieve options for registering a new WebAuthn credential.
struct WebAuthnLoginGetCredentialCreationOptionsRequest: Request {
    typealias Response = WebAuthnLoginCredentialCreationOptionsResponse

    var body: SecretVerificationRequestModel? { requestModel }

    var path: String { "/webauthn/attestation-options" }

    var method: HTTPMethod { .post }

    let requestModel: SecretVerificationRequestModel
}
