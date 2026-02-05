import Foundation

// MARK: - DeviceAuthKeyMetadata

/// Metadata needed for matching a request to the device passkey before decrypting the secret data.
public struct DeviceAuthKeyMetadata: Codable, Equatable, Sendable {
    /// The unique identifier of the cipher associated with this device auth key.
    public let cipherId: String

    /// The unique identifier for this credential.
    public let credentialId: Data

    /// The relying party identifier, typically a domain name.
    public let rpId: String

    /// The user handle (user ID) as raw data.
    public let userHandle: Data

    /// The user's username or login name.
    public let userName: String

    /// Creates new device auth key metadata.
    ///
    /// - Parameters:
    ///   - cipherId: The unique identifier of the cipher associated with this device auth key.
    ///   - credentialId: The unique identifier for this credential.
    ///   - rpId: The relying party identifier, typically a domain name.
    ///   - userHandle: The user handle (user ID) as raw data.
    ///   - userName: The user's username or login name.
    public init(
        cipherId: String,
        credentialId: Data,
        rpId: String,
        userHandle: Data,
        userName: String,
    ) {
        self.cipherId = cipherId
        self.credentialId = credentialId
        self.rpId = rpId
        self.userHandle = userHandle
        self.userName = userName
    }
}
