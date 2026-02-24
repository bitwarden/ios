import BitwardenSdk
import Foundation
import Networking

// MARK: - WebAuthnLoginCredentialAssertionOptionsResponse

/// Parameters received from the server for initializing a WebAuthn credential assertion flow.
struct WebAuthnLoginCredentialAssertionOptionsResponse: JSONResponse, Equatable, Sendable {
    /// Options to be provided to the WebAuthn authenticator.
    let options: WebAuthnPublicKeyCredentialRequestOptions

    /// Contains an encrypted version of the `options`.
    /// Used by the server to validate the assertion response.
    let token: EncString
}
