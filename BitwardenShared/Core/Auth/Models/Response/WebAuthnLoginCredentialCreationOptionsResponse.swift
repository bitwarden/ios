import Foundation
import Networking

// MARK: WebAuthnLoginCredentialCreationOptionsResponse

/// Parameters received from the server to initiate a WebAuthn credential creation flow.
struct WebAuthnLoginCredentialCreationOptionsResponse: JSONResponse, Equatable, Sendable {
    /// Options to be provided to the WebAuthn authenticator.
    let options: WebAuthnPublicKeyCredentialCreationOptions

    /// Contains an encrypted version of the {@link options}.
    /// Used by the server to validate the attestation response of newly created credentials.
    let token: String
}
