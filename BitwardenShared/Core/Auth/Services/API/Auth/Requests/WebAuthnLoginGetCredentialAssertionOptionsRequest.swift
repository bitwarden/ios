//
//  WebAuthnLoginGetCredentialCreationOptionsRequest 2.swift
//  Bitwarden
//
//  Created by Isaiah Inuwa on 2025-09-19.
//


import Networking

struct WebAuthnLoginGetCredentialCreationOptionsRequest : Request {
    typealias Response = WebAuthnLoginCredentialCreationOptionsResponse
    
    var body: SecretVerificationRequestModel { requestModel }
    
    var path: String { "/webauthn/attestation-options" }
    
    var method: HTTPMethod { .post }
    
    let requestModel: SecretVerificationRequestModel
    
    
}
