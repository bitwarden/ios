import Foundation

/// Stored key material needed to assert the device auth key passkey.
public struct DeviceAuthKeyRecord: Codable, Equatable, Sendable {
    /// The unique identifier of the cipher associated with this device auth key.
    public let cipherId: String

    /// The human-readable name of the cipher.
    public let cipherName: String

    /// The signature counter value, used to detect cloned authenticators.
    public let counter: String

    /// The date when this credential was created.
    public let creationDate: Date

    /// The unique identifier for this credential, assigned by the authenticator.
    public let credentialId: String

    /// Whether this credential is discoverable (formerly called "resident key").
    /// A discoverable credential can be used without providing a credential ID.
    public let discoverable: String

    /// The HMAC secret, if the credential supports the hmac-secret extension.
    public let hmacSecret: String?

    /// The type of public key credential (typically "public-key").
    public let keyType: String

    /// The algorithm used for the key (e.g., "ES256" for ECDSA with SHA-256).
    public let keyAlgorithm: String

    /// The elliptic curve used for the key (e.g., "P-256").
    public let keyCurve: String

    /// The actual key material value.
    public let keyValue: String

    /// The relying party identifier, typically a domain name.
    public let rpId: String

    /// The human-readable name of the relying party.
    public let rpName: String?

    /// The user identifier for the relying party.
    public let userId: String?

    /// The user's username or login name.
    public let userName: String?

    /// The user's human-readable display name.
    public let userDisplayName: String?

    /// Creates a new device auth key record.
    ///
    /// - Parameters:
    ///   - cipherId: The unique identifier of the cipher associated with this device auth key.
    ///   - cipherName: The human-readable name of the cipher.
    ///   - counter: The signature counter value, used to detect cloned authenticators.
    ///   - creationDate: The date when this credential was created.
    ///   - credentialId: The unique identifier for this credential, assigned by the authenticator.
    ///   - discoverable: Whether this credential is discoverable (formerly called "resident key").
    ///   - hmacSecret: The HMAC secret, if the credential supports the hmac-secret extension.
    ///   - keyType: The type of public key credential (typically "public-key").
    ///   - keyAlgorithm: The algorithm used for the key (e.g., "ES256" for ECDSA with SHA-256).
    ///   - keyCurve: The elliptic curve used for the key (e.g., "P-256").
    ///   - keyValue: The actual key material value.
    ///   - rpId: The relying party identifier, typically a domain name.
    ///   - rpName: The human-readable name of the relying party.
    ///   - userId: The user identifier for the relying party.
    ///   - userName: The user's username or login name.
    ///   - userDisplayName: The user's human-readable display name.
    public init(
        cipherId: String,
        cipherName: String,
        counter: String,
        creationDate: Date,
        credentialId: String,
        discoverable: String,
        hmacSecret: String?,
        keyType: String,
        keyAlgorithm: String,
        keyCurve: String,
        keyValue: String,
        rpId: String,
        rpName: String?,
        userId: String?,
        userName: String?,
        userDisplayName: String?,
    ) {
        self.cipherId = cipherId
        self.cipherName = cipherName
        self.counter = counter
        self.creationDate = creationDate
        self.credentialId = credentialId
        self.discoverable = discoverable
        self.hmacSecret = hmacSecret
        self.keyType = keyType
        self.keyAlgorithm = keyAlgorithm
        self.keyCurve = keyCurve
        self.keyValue = keyValue
        self.rpId = rpId
        self.rpName = rpName
        self.userId = userId
        self.userName = userName
        self.userDisplayName = userDisplayName
    }
}
