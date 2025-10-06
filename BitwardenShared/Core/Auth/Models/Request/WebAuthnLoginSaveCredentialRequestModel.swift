//
//  WebAuthnLoginSaveCredentialRequestModel.swift
//  Bitwarden
//
//  Created by Isaiah Inuwa on 2025-10-03.
//


import Foundation
import Networking

// MARK: - SaveCredentialRequestModel

/// The request body for an answer login request request.
///
struct WebAuthnLoginSaveCredentialRequestModel: JSONRequestBody, Equatable {
    static let encoder = JSONEncoder()

    // MARK: Properties
    // The response received from the authenticator.
    // This contains all information needed for future authentication flows.
    let deviceResponse: WebAuthnLoginAttestationResponseRequest

    // Nickname chosen by the user to identify this credential
    let name: String

    // Token required by the server to complete the creation.
    // It contains encrypted information that the server needs to verify the credential.
    let token: String

    // True if the credential was created with PRF support.
    let supportsPrf: Bool

    // Used for vault encryption. See {@link RotateableKeySet.encryptedUserKey }
    let encryptedUserKey: String?

    // Used for vault encryption. See {@link RotateableKeySet.encryptedPublicKey }
    let encryptedPublicKey: String?

    // Used for vault encryption. See {@link RotateableKeySet.encryptedPrivateKey }
    let encryptedPrivateKey: String?
}

struct WebAuthnLoginAttestationResponseRequest: Encodable, Equatable {
    let id: String
    let rawId: String
    let type: String
    // let extensions: [String: Any]
    let response: WebAuthnLoginAttestationResponseRequestInner
}

struct WebAuthnLoginAttestationResponseRequestInner: Encodable, Equatable {
    let attestationObject: String
    let clientDataJson: String
    
}