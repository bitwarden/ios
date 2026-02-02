import Foundation

// MARK: - DeviceAuthKeyMetadata

/// Metadata needed for matching a request to the device passkey before decrypting the secret data.
public struct DeviceAuthKeyMetadata: Codable, Equatable, Sendable {
    /// The unique identifier for this credential.
    public let credentialId: Data

    /// The unique identifier of the cipher associated with this device auth key.
    public let cipherId: String

    /// The relying party identifier, typically a domain name.
    public let rpId: String

    /// The user's username or login name.
    public let userName: String

    /// The user handle (user ID) as raw data.
    public let userHandle: Data

    /// Creates new device auth key metadata.
    ///
    /// - Parameters:
    ///   - credentialId: The unique identifier for this credential.
    ///   - cipherId: The unique identifier of the cipher associated with this device auth key.
    ///   - rpId: The relying party identifier, typically a domain name.
    ///   - userName: The user's username or login name.
    ///   - userHandle: The user handle (user ID) as raw data.
    public init(
        credentialId: Data,
        cipherId: String,
        rpId: String,
        userName: String,
        userHandle: Data,
    ) {
        self.credentialId = credentialId
        self.cipherId = cipherId
        self.rpId = rpId
        self.userName = userName
        self.userHandle = userHandle
    }
}
