//
//  WebAuthnLoginGetCredentialCreationOptionsRequest.swift
//  Bitwarden
//
//  Created by Isaiah Inuwa on 2025-10-03.
//


import Networking

struct WebAuthnLoginGetCredentialCreationOptionsRequest : Request {
    typealias Response = WebAuthnLoginCredentialCreationOptionsResponse
    
    var body: SecretVerificationRequestModel? { requestModel }
    
    var path: String { "/webauthn/attestation-options" }
    
    var method: HTTPMethod { .post }
    
    let requestModel: SecretVerificationRequestModel
}