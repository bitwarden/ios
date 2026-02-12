import BitwardenShared
import Foundation

public extension DeviceAuthKeyMetadata {
    /// Creates a test fixture for device auth key metadata with default values.
    ///
    /// - Parameters:
    ///   - cipherId: The unique identifier of the cipher. Defaults to `"cipher-123"`.
    ///   - credentialId: The unique identifier for this credential.
    ///                     Defaults to `Data("credential-456".utf8)`.
    ///   - rpId: The relying party identifier. Defaults to `"bitwarden.com"`.
    ///   - userHandle: The user handle (user ID) as raw data. Defaults to `Data("user-id".utf8)`.
    ///   - userName: The user's username or login name. Defaults to `"user@example.com"`.
    /// - Returns: A `DeviceAuthKeyMetadata` configured with the specified or default values.
    static func fixture(
        cipherId: String = "cipher-123",
        credentialId: Data = Data("credential-456".utf8),
        rpId: String = "bitwarden.com",
        userHandle: Data = Data("user-id".utf8),
        userName: String = "user@example.com",
    ) -> DeviceAuthKeyMetadata {
        DeviceAuthKeyMetadata(
            cipherId: cipherId,
            credentialId: credentialId,
            rpId: rpId,
            userHandle: userHandle,
            userName: userName,
        )
    }
}
