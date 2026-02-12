import BitwardenSdk
import Foundation

/// Stored key material needed to assert the device auth key passkey.
public struct DeviceAuthKeyRecord: Codable, Equatable, Sendable {
    /// The unique identifier of the cipher associated with this device auth key.
    public let cipherId: EncString

    /// The human-readable name of the cipher.
    public let cipherName: EncString

    /// The signature counter value, used to detect cloned authenticators.
    public let counter: EncString

    /// The date when this credential was created.
    public let creationDate: Date

    /// The unique identifier for this credential, assigned by the authenticator.
    public let credentialId: EncString

    /// Whether this credential is discoverable (formerly called "resident key").
    /// A discoverable credential can be used without providing a credential ID.
    public let discoverable: EncString

    /// The HMAC secret, if the credential supports the hmac-secret extension.
    public let hmacSecret: EncString?

    /// The algorithm used for the key (e.g., "ES256" for ECDSA with SHA-256).
    public let keyAlgorithm: EncString

    /// The elliptic curve used for the key (e.g., "P-256").
    public let keyCurve: EncString

    /// The type of public key credential (typically "public-key").
    public let keyType: EncString

    /// The actual key material value.
    public let keyValue: EncString

    /// The relying party identifier, typically a domain name.
    public let rpId: EncString

    /// The human-readable name of the relying party.
    public let rpName: EncString?

    /// The user's human-readable display name.
    public let userDisplayName: EncString?

    /// The user identifier for the relying party.
    public let userId: EncString?

    /// The user's username or login name.
    public let userName: EncString?

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
    ///   - keyAlgorithm: The algorithm used for the key (e.g., "ES256" for ECDSA with SHA-256).
    ///   - keyCurve: The elliptic curve used for the key (e.g., "P-256").
    ///   - keyType: The type of public key credential (typically "public-key").
    ///   - keyValue: The actual key material value.
    ///   - rpId: The relying party identifier, typically a domain name.
    ///   - rpName: The human-readable name of the relying party.
    ///   - userDisplayName: The user's human-readable display name.
    ///   - userId: The user identifier for the relying party.
    ///   - userName: The user's username or login name.
    public init(
        cipherId: EncString,
        cipherName: EncString,
        counter: EncString,
        creationDate: Date,
        credentialId: EncString,
        discoverable: EncString,
        hmacSecret: EncString?,
        keyAlgorithm: EncString,
        keyCurve: EncString,
        keyType: EncString,
        keyValue: EncString,
        rpId: EncString,
        rpName: EncString?,
        userDisplayName: EncString?,
        userId: EncString?,
        userName: EncString?,
    ) {
        self.cipherId = cipherId
        self.cipherName = cipherName
        self.counter = counter
        self.creationDate = creationDate
        self.credentialId = credentialId
        self.discoverable = discoverable
        self.hmacSecret = hmacSecret
        self.keyAlgorithm = keyAlgorithm
        self.keyCurve = keyCurve
        self.keyType = keyType
        self.keyValue = keyValue
        self.rpId = rpId
        self.rpName = rpName
        self.userDisplayName = userDisplayName
        self.userId = userId
        self.userName = userName
    }
}
