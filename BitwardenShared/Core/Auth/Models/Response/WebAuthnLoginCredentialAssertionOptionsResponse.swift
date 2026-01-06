import Foundation
import Networking

// MARK: WebAuthnLoginCredentialAssertionOptionsResponse

/// Parameters received from the server for initializing a WebAuthn credential assertion flow.
struct WebAuthnLoginCredentialAssertionOptionsResponse: JSONResponse, Equatable, Sendable {
    /// Options to be provided to the webauthn authenticator.
    let options: PublicKeyCredentialRequestOptions

    /// Contains an encrypted version of the {@link options}.
    /// Used by the server to validate the attestation response of newly created credentials.
    let token: String
}

// MARK: PublicKeyCredentialAssertionOptions

/// WebAuthn PublicKeyCredentialRequestOptions.
struct PublicKeyCredentialRequestOptions: Codable, Equatable, Hashable {
    let allowCredentials: [BwPublicKeyCredentialDescriptor]?
    let challenge: String
    let extensions: AuthenticationExtensionsClientInputs?
    let rpId: String
    let timeout: Int?
}
