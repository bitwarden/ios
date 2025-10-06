//
//  WebAuthnLoginCredentialAssertionOptionsResponse.swift
//  Bitwarden
//
//  Created by Isaiah Inuwa on 2025-10-03.
//


import Foundation
import Networking

struct WebAuthnLoginCredentialAssertionOptionsResponse: JSONResponse, Equatable, Sendable {
    /// Options to be provided to the webauthn authenticator.
    let options: PublicKeyCredentialAssertionOptions;

    /// Contains an encrypted version of the {@link options}.
    /// Used by the server to validate the attestation response of newly created credentials.
    let token: String;
}

struct PublicKeyCredentialAssertionOptions: Codable, Equatable, Hashable {
    let allowCredentials: [BwPublicKeyCredentialDescriptor]?
    let challenge: String
    let extensions: AuthenticationExtensionsClientInputs?
    let rpId: String
    let timeout: Int?
}