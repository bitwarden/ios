import BitwardenShared
import Foundation

public extension DeviceAuthKeyRecord {
    /// Creates a test fixture for a device auth key record with default encrypted values.
    ///
    /// - Parameters:
    ///   - cipherId: The unique identifier of the cipher. Defaults to `"encrypted-cipher-123"`.
    ///   - cipherName: The human-readable name of the cipher. Defaults to `"encrypted-Test Device Key"`.
    ///   - counter: The signature counter value. Defaults to `"encrypted-0"`.
    ///   - creationDate: The date when this credential was created.
    ///                   Defaults to `Date(timeIntervalSince1970: 1_234_567_890)`.
    ///   - credentialId: The unique identifier for this credential. Defaults to `"encrypted-credential-456"`.
    ///   - discoverable: Whether this credential is discoverable. Defaults to `"encrypted-true"`.
    ///   - hmacSecret: The HMAC secret. Defaults to `"encrypted-hmac-secret"`.
    ///   - keyType: The type of public key credential. Defaults to `"encrypted-public-key"`.
    ///   - keyAlgorithm: The algorithm used for the key. Defaults to `"encrypted-ES256"`.
    ///   - keyCurve: The elliptic curve used for the key. Defaults to `"encrypted-P-256"`.
    ///   - keyValue: The actual key material value. Defaults to `"encrypted-key-value-789"`.
    ///   - rpId: The relying party identifier. Defaults to `"encrypted-bitwarden.com"`.
    ///   - rpName: The human-readable name of the relying party. Defaults to `"encrypted-Bitwarden"`.
    ///   - userId: The user identifier for the relying party. Defaults to `"encrypted-user-id"`.
    ///   - userName: The user's username or login name. Defaults to `"encrypted-user@example.com"`.
    ///   - userDisplayName: The user's human-readable display name. Defaults to `"encrypted-Test User"`.
    /// - Returns: A `DeviceAuthKeyRecord` configured with the specified or default values.
    static func fixture(
        cipherId: String = "encrypted-cipher-123",
        cipherName: String = "encrypted-Test Device Key",
        counter: String = "encrypted-0",
        creationDate: Date = Date(timeIntervalSince1970: 1_234_567_890),
        credentialId: String = "encrypted-credential-456",
        discoverable: String = "encrypted-true",
        hmacSecret: String? = "encrypted-hmac-secret",
        keyType: String = "encrypted-public-key",
        keyAlgorithm: String = "encrypted-ES256",
        keyCurve: String = "encrypted-P-256",
        keyValue: String = "encrypted-key-value-789",
        rpId: String = "encrypted-bitwarden.com",
        rpName: String? = "encrypted-Bitwarden",
        userId: String? = "encrypted-user-id",
        userName: String? = "encrypted-user@example.com",
        userDisplayName: String? = "encrypted-Test User",
    ) -> DeviceAuthKeyRecord {
        DeviceAuthKeyRecord(
            cipherId: cipherId,
            cipherName: cipherName,
            counter: counter,
            creationDate: creationDate,
            credentialId: credentialId,
            discoverable: discoverable,
            hmacSecret: hmacSecret,
            keyType: keyType,
            keyAlgorithm: keyAlgorithm,
            keyCurve: keyCurve,
            keyValue: keyValue,
            rpId: rpId,
            rpName: rpName,
            userId: userId,
            userName: userName,
            userDisplayName: userDisplayName,
        )
    }
}
