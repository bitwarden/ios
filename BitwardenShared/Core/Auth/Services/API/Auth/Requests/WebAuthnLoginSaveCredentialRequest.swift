import Networking

struct WebAuthnLoginSaveCredentialRequest : Request {
    typealias Response = EmptyResponse
    
    var body: WebAuthnLoginSaveCredentialRequestModel { requestModel }
    
    var path: String { "/webauthn" }
    
    var method: HTTPMethod { .post }
    
    let requestModel: WebAuthnLoginSaveCredentialRequestModel
    
    
}
