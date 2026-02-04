import BitwardenShared
import Foundation

public extension DeviceAuthKeyMetadata {
    /// Creates a test fixture for device auth key metadata with default encrypted values.
    ///
    /// - Parameters:
    ///   - credentialId: The unique identifier for this credential.
    ///                     Defaults to `Data("encrypted-credential-456".utf8)`.
    ///   - cipherId: The unique identifier of the cipher. Defaults to `"encrypted-cipher-123"`.
    ///   - rpId: The relying party identifier. Defaults to `"encrypted-bitwarden.com"`.
    ///   - userName: The user's username or login name. Defaults to `"encrypted-user@example.com"`.
    ///   - userHandle: The user handle (user ID) as raw data. Defaults to `Data("encrypted-user-id".utf8)`.
    /// - Returns: A `DeviceAuthKeyMetadata` configured with the specified or default values.
    static func fixture(
        credentialId: Data = Data("encrypted-credential-456".utf8),
        cipherId: String = "encrypted-cipher-123",
        rpId: String = "encrypted-bitwarden.com",
        userName: String = "encrypted-user@example.com",
        userHandle: Data = Data("encrypted-user-id".utf8),
    ) -> DeviceAuthKeyMetadata {
        DeviceAuthKeyMetadata(
            credentialId: credentialId,
            cipherId: cipherId,
            rpId: rpId,
            userName: userName,
            userHandle: userHandle,
        )
    }
}
