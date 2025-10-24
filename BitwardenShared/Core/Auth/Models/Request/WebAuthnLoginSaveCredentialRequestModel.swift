import Foundation
import Networking

// MARK: WebAuthnLoginSaveCredentialRequestModel

/// The request body for a request to save a WebAuthn credential.
struct WebAuthnLoginSaveCredentialRequestModel: JSONRequestBody, Equatable {
    // MARK: Properties

    /// The response received from the authenticator.
    /// This contains all information needed for future authentication flows.
    let deviceResponse: WebAuthnLoginAttestationResponseRequest

    /// Encapsulated user key in rotateable key set.
    let encryptedUserKey: String?

    /// Encrypted public key in rotateable key set.
    let encryptedPublicKey: String?

    /// Encrypted private key in rotatable key set.
    let encryptedPrivateKey: String?

    /// Nickname chosen by the user to identify this credential
    let name: String

    /// `true` if the credential was created with PRF support.
    let supportsPrf: Bool

    /// Token required by the server to complete the creation.
    /// It contains encrypted information that the server needs to verify the credential.
    let token: String
}

// MARK: WebAuthnLoginAttestationResponseRequest

/// Fields corresponding to a WebAuthn PublicKeyCredential with an AuthenticatorAttestationResponse.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#iface-pkcredential)
struct WebAuthnLoginAttestationResponseRequest: Encodable, Equatable {
    let id: String
    let rawId: String
    let response: WebAuthnLoginAttestationResponseRequestInner
    let type: String
    // We are currently not sending back any extension results to the server, so we are omitting this slot.
    // let clientExtensionsResults: [String: Any]
}

// MARK: WebAuthnLoginAttestationResponseRequestInner

/// Fields corresponding to a WebAuthn AuthenticatorAttestationResponse.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#authenticatorattestationresponse)
struct WebAuthnLoginAttestationResponseRequestInner: Encodable, Equatable {
    /// Attestation object received from the authenticator, encoded in base64url.
    let attestationObject: String

    /// JSON object of Client Data used for the request.
    let clientDataJson: String
}
