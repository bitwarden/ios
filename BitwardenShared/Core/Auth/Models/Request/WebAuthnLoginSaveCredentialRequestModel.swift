import Foundation
import Networking

/// The request body for a request to save a WebAuthn credential for authenticating or decrypting the Bitwarden account.
struct WebAuthnLoginSaveCredentialRequestModel: JSONRequestBody, Equatable {
    // MARK: Properties

    /// The response received from the authenticator.
    /// This contains all information needed for future authentication flows.
    let deviceResponse: WebAuthnPublicKeyCredentialWithAttestationResponse

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
