//
//  WebAuthnLoginCredentialCreationOptionsResponse.swift
//  Bitwarden
//
//  Created by Isaiah Inuwa on 2025-10-03.
//


import Foundation
import Networking

struct WebAuthnLoginCredentialCreationOptionsResponse: JSONResponse, Equatable, Sendable {
    /// Options to be provided to the webauthn authenticator.
    let options: PublicKeyCredentialCreationOptions;

    /// Contains an encrypted version of the {@link options}.
    /// Used by the server to validate the attestation response of newly created credentials.
    let token: String;
}

struct PublicKeyCredentialCreationOptions: Codable, Equatable, Hashable {
    // attestation?: AttestationConveyancePreference
    // let authenticatorSelection: AuthenticatorSelectionCriteria?
    let challenge: String
    let excludeCredentials: [BwPublicKeyCredentialDescriptor]?
    let extensions: AuthenticationExtensionsClientInputs?
    let pubKeyCredParams: [BwPublicKeyCredentialParameters]
    let rp: BwPublicKeyCredentialRpEntity
    let timeout: Int?
    let user: BwPublicKeyCredentialUserEntity
}


struct AuthenticationExtensionsClientInputs: Codable, Equatable, Hashable {
    let prf: AuthenticationExtensionsPRFInputs?
}

struct AuthenticationExtensionsPRFInputs: Codable, Equatable, Hashable {
    let eval: AuthenticationExtensionsPRFValues?
    let evalByCredential: [String: AuthenticationExtensionsPRFValues]?
}

struct AuthenticationExtensionsPRFValues: Codable, Equatable, Hashable {
    let first: String
    let second: String?
}

struct BwPublicKeyCredentialDescriptor: Codable, Equatable, Hashable {
    let type: String
    let id: String
    // let transports: [String]?
}

struct BwPublicKeyCredentialParameters: Codable, Equatable, Hashable {
    let type: String
    let alg: Int
}

struct BwPublicKeyCredentialRpEntity: Codable, Equatable, Hashable {
    let id: String
    let name: String
}

struct BwPublicKeyCredentialUserEntity: Codable, Equatable, Hashable {
    let id: String
    let name: String
}