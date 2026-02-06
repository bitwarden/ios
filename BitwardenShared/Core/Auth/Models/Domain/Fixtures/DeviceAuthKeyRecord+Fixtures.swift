import BitwardenSdk
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
    ///   - keyAlgorithm: The algorithm used for the key. Defaults to `"encrypted-ES256"`.
    ///   - keyCurve: The elliptic curve used for the key. Defaults to `"encrypted-P-256"`.
    ///   - keyType: The type of public key credential. Defaults to `"encrypted-public-key"`.
    ///   - keyValue: The actual key material value. Defaults to `"encrypted-key-value-789"`.
    ///   - rpId: The relying party identifier. Defaults to `"encrypted-bitwarden.com"`.
    ///   - rpName: The human-readable name of the relying party. Defaults to `"encrypted-Bitwarden"`.
    ///   - userDisplayName: The user's human-readable display name. Defaults to `"encrypted-Test User"`.
    ///   - userId: The user identifier for the relying party. Defaults to `"encrypted-user-id"`.
    ///   - userName: The user's username or login name. Defaults to `"encrypted-user@example.com"`.
    /// - Returns: A `DeviceAuthKeyRecord` configured with the specified or default values.
    static func fixture(
        cipherId: EncString = "encrypted-cipher-123",
        cipherName: EncString = "encrypted-Test Device Key",
        counter: EncString = "encrypted-0",
        creationDate: Date = Date(timeIntervalSince1970: 1_234_567_890),
        credentialId: EncString = "encrypted-credential-456",
        discoverable: EncString = "encrypted-true",
        hmacSecret: EncString? = "encrypted-hmac-secret",
        keyAlgorithm: EncString = "encrypted-ES256",
        keyCurve: EncString = "encrypted-P-256",
        keyType: EncString = "encrypted-public-key",
        keyValue: EncString = "encrypted-key-value-789",
        rpId: EncString = "encrypted-bitwarden.com",
        rpName: EncString? = "encrypted-Bitwarden",
        userDisplayName: EncString? = "encrypted-Test User",
        userId: EncString? = "encrypted-user-id",
        userName: EncString? = "encrypted-user@example.com",
    ) -> DeviceAuthKeyRecord {
        DeviceAuthKeyRecord(
            cipherId: cipherId,
            cipherName: cipherName,
            counter: counter,
            creationDate: creationDate,
            credentialId: credentialId,
            discoverable: discoverable,
            hmacSecret: hmacSecret,
            keyAlgorithm: keyAlgorithm,
            keyCurve: keyCurve,
            keyType: keyType,
            keyValue: keyValue,
            rpId: rpId,
            rpName: rpName,
            userDisplayName: userDisplayName,
            userId: userId,
            userName: userName,
        )
    }
}
