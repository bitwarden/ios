import BitwardenSdk
import Foundation

// MARK: - DeviceAuthKeyRecord

/// Stored key material needed to assert the device auth key passkey.
public struct DeviceAuthKeyRecord: Codable, Equatable, Sendable {
    /// The signature counter value, used to detect cloned authenticators.
    public let counter: UInt32

    /// The unique identifier for this credential, assigned by the authenticator.
    public let credentialId: Data

    /// The HMAC secret, if the credential supports the hmac-secret extension.
    public let hmacSecret: Data

    /// The COSE algorithm identifier used for the key (e.g., `-7` for ECDSA with SHA-256).
    public let keyAlgorithm: Int64

    /// The COSE elliptic curve identifier used for the key (e.g., `1` for P-256).
    public let keyCurve: Int64

    /// The actual key material value.
    public let keyValue: Data

    /// The relying party identifier, typically the domain name of the Bitwarden Web Vault.
    public let rpId: String

    /// The human-readable name of the relying party.
    public let rpName: String

    /// The user identifier for the relying party.
    public let userId: Data

    /// Creates a new device auth key record.
    ///
    /// - Parameters:
    ///   - counter: The signature counter value, used to detect cloned authenticators.
    ///   - credentialId: The unique identifier for this credential, assigned by the authenticator.
    ///   - discoverable: Whether this credential is discoverable (formerly called "resident key").
    ///   - hmacSecret: The HMAC secret, if the credential supports the hmac-secret extension.
    ///   - keyAlgorithm: The algorithm used for the key (e.g., "ES256" for ECDSA with SHA-256).
    ///   - keyCurve: The elliptic curve used for the key (e.g., "P-256").
    ///   - keyType: The type of public key credential (typically "public-key").
    ///   - keyValue: The actual key material value.
    ///   - rpId: The relying party identifier, typically a domain name.
    ///   - rpName: The human-readable name of the relying party.
    ///   - userId: The user identifier for the relying party.
    public init(
        counter: UInt32,
        credentialId: Data,
        hmacSecret: Data,
        keyAlgorithm: Int64,
        keyCurve: Int64,
        keyValue: Data,
        rpId: String,
        rpName: String,
        userId: Data,
    ) {
        self.counter = counter
        self.credentialId = credentialId
        self.hmacSecret = hmacSecret
        self.keyAlgorithm = keyAlgorithm
        self.keyCurve = keyCurve
        self.keyValue = keyValue
        self.rpId = rpId
        self.rpName = rpName
        self.userId = userId
    }
}
