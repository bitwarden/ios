import Foundation

// MARK: - DeviceAuthKeyMetadata

/// Metadata needed for matching a request to the device passkey before decrypting the secret data.
public struct DeviceAuthKeyMetadata: Codable, Equatable, Sendable {
    /// The date this credential was created.
    public let creationDate: Date

    /// The unique identifier for this credential.
    public let credentialId: Data

    /// The unique identifier of the cipher associated with this device auth key.
    public let recordIdentifier: String

    /// The relying party identifier, typically the Bitwarden Web Vault domain name.
    public let rpId: String

    /// The display name for the WebAuthn user.
    public let userDisplayName: String

    /// The WebAuthn user handle (user ID) as raw data.
    public let userHandle: Data

    /// The user's username or login name.
    public let userName: String

    /// Creates new device auth key metadata.
    ///
    /// - Parameters:
    ///   - creationDate:The date this credential was created.
    ///   - credentialId: The unique identifier for this credential.
    ///   - recordIdentifier: The unique identifier of this device auth key.
    ///   - rpId: The relying party identifier, typically a domain name.
    ///   - userDisplayName:The display name for the WebAuthn user.
    ///   - userHandle: The user handle (user ID) as raw data.
    ///   - userName: The user's username or login name.
    public init(
        creationDate: Date,
        credentialId: Data,
        recordIdentifier: String,
        rpId: String,
        userDisplayName: String,
        userHandle: Data,
        userName: String,
    ) {
        self.creationDate = creationDate
        self.credentialId = credentialId
        self.recordIdentifier = recordIdentifier
        self.rpId = rpId
        self.userDisplayName = userDisplayName
        self.userHandle = userHandle
        self.userName = userName
    }
}
