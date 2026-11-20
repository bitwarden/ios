import BitwardenShared
import Foundation

public extension DeviceAuthKeyKeychainRecord {
    /// Creates a test fixture for a device auth key record with default values.
    ///
    /// - Parameters:
    ///   - counter: The signature counter value. Defaults to `0`.
    ///   - credentialId: The unique identifier for this credential. Defaults to `Data("credential-456".utf8)`.
    ///   - hmacSecret: The HMAC secret seed. Defaults to 32 bytes of `0x01`.
    ///   - key: The COSE key. Defaults to `Data("cose-key".utf8)`.
    ///   - rpId: The relying party identifier. Defaults to `"bitwarden.com"`.
    ///   - userId: The WebAuthn user handle. Defaults to `Data("user-id".utf8)`.
    /// - Returns: A `DeviceAuthKeyKeychainRecord` configured with the specified or default values.
    static func fixture(
        counter: UInt32? = 0,
        credentialId: Data = Data("credential-456".utf8),
        hmacSecret: Data = Data(repeating: 1, count: 32),
        key: Data = Data("cose-key".utf8),
        rpId: String = "bitwarden.com",
        userId: Data = Data("user-id".utf8),
    ) -> DeviceAuthKeyKeychainRecord {
        DeviceAuthKeyKeychainRecord(
            counter: counter,
            credentialId: credentialId,
            hmacSecret: hmacSecret,
            key: key,
            rpId: rpId,
            userId: userId,
        )
    }
}
