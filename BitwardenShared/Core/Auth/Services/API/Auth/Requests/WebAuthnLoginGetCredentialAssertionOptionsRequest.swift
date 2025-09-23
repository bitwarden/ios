import Networking

struct WebAuthnLoginGetCredentialAssertionOptionsRequest : Request {
    typealias Response = WebAuthnLoginCredentialAssertionOptionsResponse
    
    var body: SecretVerificationRequestModel? { requestModel }
    
    var path: String { "/webauthn/assertion-options" }
    
    var method: HTTPMethod { .post }
    
    let requestModel: SecretVerificationRequestModel
}
