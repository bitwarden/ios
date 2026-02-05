import BitwardenShared
import Foundation

public extension DeviceAuthKeyMetadata {
    /// Creates a test fixture for device auth key metadata with default encrypted values.
    ///
    /// - Parameters:
    ///   - cipherId: The unique identifier of the cipher. Defaults to `"encrypted-cipher-123"`.
    ///   - credentialId: The unique identifier for this credential.
    ///                     Defaults to `Data("encrypted-credential-456".utf8)`.
    ///   - rpId: The relying party identifier. Defaults to `"encrypted-bitwarden.com"`.
    ///   - userHandle: The user handle (user ID) as raw data. Defaults to `Data("encrypted-user-id".utf8)`.
    ///   - userName: The user's username or login name. Defaults to `"encrypted-user@example.com"`.
    /// - Returns: A `DeviceAuthKeyMetadata` configured with the specified or default values.
    static func fixture(
        cipherId: String = "encrypted-cipher-123",
        credentialId: Data = Data("encrypted-credential-456".utf8),
        rpId: String = "encrypted-bitwarden.com",
        userHandle: Data = Data("encrypted-user-id".utf8),
        userName: String = "encrypted-user@example.com",
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
