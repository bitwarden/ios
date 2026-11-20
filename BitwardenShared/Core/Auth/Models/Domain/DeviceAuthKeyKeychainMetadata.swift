import Foundation

// MARK: - DeviceAuthKeyKeychainMetadata

/// Metadata needed for matching a request to the device passkey before decrypting the secret data.
public struct DeviceAuthKeyKeychainMetadata: Codable, Equatable, Sendable {
    /// The record identifier of this device auth key. This is the ID that the server assigned to
    /// the WebAuthn login credential. It's also used as the `ASPasskeyCredentialIdentity`
    /// record identifier.
    public let cipherId: String

    /// The date the device auth key was created.
    public let creationDate: Date?

    /// The unique identifier for this credential.
    public let credentialId: Data

    /// The private key of the PRF key set, encrypted with the key derived from the PRF output.
    /// Together with `encryptedUserKey`, this unlocks the vault with the device auth key.
    public var encryptedPrivateKey: String?

    /// The user key of the PRF key set, encapsulated with the public key of the key set.
    public var encryptedUserKey: String?

    /// Whether the account was created without a master password that the user knows, so the
    /// device auth key is the account's primary way to log in and unlock.
    public var isPasswordlessAccount: Bool

    /// The relying party identifier, typically a domain name.
    public let rpId: String

    /// The user's display name.
    public let userDisplayName: String?

    /// The user handle (user ID) as raw data.
    public let userHandle: Data

    /// The user's username or login name.
    public let userName: String

    /// Creates new device auth key metadata.
    ///
    /// - Parameters:
    ///   - cipherId: The record identifier of this device auth key.
    ///   - creationDate: The date the device auth key was created.
    ///   - credentialId: The unique identifier for this credential.
    ///   - encryptedPrivateKey: The private key of the PRF key set, encrypted with the PRF key.
    ///   - encryptedUserKey: The user key of the PRF key set, encapsulated with the public key.
    ///   - isPasswordlessAccount: Whether the account has no master password that the user knows.
    ///   - rpId: The relying party identifier, typically a domain name.
    ///   - userDisplayName: The user's display name.
    ///   - userHandle: The user handle (user ID) as raw data.
    ///   - userName: The user's username or login name.
    public init(
        cipherId: String,
        creationDate: Date? = nil,
        credentialId: Data,
        encryptedPrivateKey: String? = nil,
        encryptedUserKey: String? = nil,
        isPasswordlessAccount: Bool = false,
        rpId: String,
        userDisplayName: String? = nil,
        userHandle: Data,
        userName: String,
    ) {
        self.cipherId = cipherId
        self.creationDate = creationDate
        self.credentialId = credentialId
        self.encryptedPrivateKey = encryptedPrivateKey
        self.encryptedUserKey = encryptedUserKey
        self.isPasswordlessAccount = isPasswordlessAccount
        self.rpId = rpId
        self.userDisplayName = userDisplayName
        self.userHandle = userHandle
        self.userName = userName
    }
}
