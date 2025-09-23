import Networking

struct WebAuthnLoginGetCredentialCreationOptionsRequest : Request {
    typealias Response = WebAuthnLoginCredentialCreateOptionsResponse
    
    var body: SecretVerificationRequestModel { requestModel }
    
    var path: String { "/webauthn/attestation-options" }
    
    var method: HTTPMethod { .post }
    
    let requestModel: SecretVerificationRequestModel
    
    
}
