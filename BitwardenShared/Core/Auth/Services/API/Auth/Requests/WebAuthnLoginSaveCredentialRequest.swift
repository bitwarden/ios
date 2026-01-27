import Networking

/// Request to store a new WebAuthn credential.
struct WebAuthnLoginSaveCredentialRequest: Request {
    typealias Response = EmptyResponse

    var body: WebAuthnLoginSaveCredentialRequestModel? { requestModel }

    var path: String { "/webauthn" }

    var method: HTTPMethod { .post }

    let requestModel: WebAuthnLoginSaveCredentialRequestModel
}
