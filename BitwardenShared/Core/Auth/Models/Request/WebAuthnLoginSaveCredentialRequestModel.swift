import BitwardenSdk
import Foundation
import Networking

/// The request body for a request to save a WebAuthn credential for authenticating or decrypting the Bitwarden account.
public struct WebAuthnLoginSaveCredentialRequestModel: JSONRequestBody, Equatable {
    // MARK: Properties

    /// The response received from the authenticator.
    /// This contains all information needed for future authentication flows.
    public let deviceResponse: WebAuthnPublicKeyCredentialWithAttestationResponse

    /// Encrypted private key in rotatable key set.
    public let encryptedPrivateKey: EncString?

    /// Encrypted public key in rotatable key set.
    public let encryptedPublicKey: EncString?

    /// Encapsulated user key in rotatable key set.
    public let encryptedUserKey: EncString?

    /// Nickname chosen by the user to identify this credential
    public let name: String

    /// `true` if the credential was created with PRF support.
    public let supportsPrf: Bool

    /// Token required by the server to complete the creation.
    /// It contains encrypted information that the server needs to verify the credential.
    public let token: String

    // MARK: Initialization

    /// Creates a new `WebAuthnLoginSaveCredentialRequestModel`.
    ///
    /// - Parameters:
    ///   - deviceResponse: The response received from the authenticator.
    ///   - encryptedPrivateKey: Encrypted private key in rotatable key set.
    ///   - encryptedPublicKey: Encrypted public key in rotatable key set.
    ///   - encryptedUserKey: Encapsulated user key in rotatable key set.
    ///   - name: Nickname chosen by the user to identify this credential.
    ///   - supportsPrf: `true` if the credential was created with PRF support.
    ///   - token: Token required by the server to complete the creation.
    public init(
        deviceResponse: WebAuthnPublicKeyCredentialWithAttestationResponse,
        encryptedPrivateKey: EncString?,
        encryptedPublicKey: EncString?,
        encryptedUserKey: EncString?,
        name: String,
        supportsPrf: Bool,
        token: String
    ) {
        self.deviceResponse = deviceResponse
        self.encryptedPrivateKey = encryptedPrivateKey
        self.encryptedPublicKey = encryptedPublicKey
        self.encryptedUserKey = encryptedUserKey
        self.name = name
        self.supportsPrf = supportsPrf
        self.token = token
    }
}
