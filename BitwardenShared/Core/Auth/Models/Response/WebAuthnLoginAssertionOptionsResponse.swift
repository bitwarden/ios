import Foundation
import Networking

// MARK: - WebAuthnLoginAssertionOptionsResponse

/// Parameters received from the identity service to log in with a WebAuthn login credential.
///
/// This only decodes the values that the device auth key needs. The server sends more values
/// (for example `userVerification` and `status`).
///
struct WebAuthnLoginAssertionOptionsResponse: JSONResponse, Equatable, Sendable {
    // MARK: Types

    /// The WebAuthn `PublicKeyCredentialRequestOptions` values that the app uses.
    struct Options: Codable, Equatable, Sendable {
        /// The challenge that the authenticator signs, encoded in base64url.
        let challenge: String

        /// The relying party identifier.
        let rpId: String?
    }

    // MARK: Properties

    /// Options to be provided to the WebAuthn authenticator.
    let options: Options

    /// A protected version of the `options`, which the server uses to validate the assertion.
    let token: String
}
