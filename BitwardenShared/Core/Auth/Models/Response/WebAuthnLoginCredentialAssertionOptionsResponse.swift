import Foundation
import Networking

/// Parameters received from the server for initializing a WebAuthn credential assertion flow.
struct WebAuthnLoginCredentialAssertionOptionsResponse: JSONResponse, Equatable, Sendable {
    /// Options to be provided to the webauthn authenticator.
    let options: WebAuthnPublicKeyCredentialRequestOptions

    /// Contains an encrypted version of the {@link options}.
    /// Used by the server to validate the attestation response of newly created credentials.
    let token: String
}
