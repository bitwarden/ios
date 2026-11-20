import Foundation

// MARK: - DeviceAuthKeyKeychainRecord

/// Stored key material needed to assert the device auth key passkey.
///
/// The values are stored as received from the SDK's `DeviceAuthKeyRecord`. The keychain item that
/// holds this record is protected by biometric access control, so the record must be usable
/// before the vault is unlocked (it is what unlocks the vault).
///
public struct DeviceAuthKeyKeychainRecord: Codable, Equatable, Sendable {
    /// The signature counter value, used to detect cloned authenticators.
    public let counter: UInt32?

    /// The unique identifier for this credential, assigned by the authenticator.
    public let credentialId: Data

    /// The HMAC secret seed (`CredRandom`) used for the hmac-secret / PRF extension.
    public let hmacSecret: Data

    /// The private key material, formatted as a COSE key.
    public let key: Data

    /// The relying party identifier, typically the host of the web vault.
    public let rpId: String

    /// The WebAuthn user handle.
    public let userId: Data

    /// Creates a new device auth key record.
    ///
    /// - Parameters:
    ///   - counter: The signature counter value, used to detect cloned authenticators.
    ///   - credentialId: The unique identifier for this credential, assigned by the authenticator.
    ///   - hmacSecret: The HMAC secret seed used for the hmac-secret / PRF extension.
    ///   - key: The private key material, formatted as a COSE key.
    ///   - rpId: The relying party identifier, typically the host of the web vault.
    ///   - userId: The WebAuthn user handle.
    ///
    public init(
        counter: UInt32?,
        credentialId: Data,
        hmacSecret: Data,
        key: Data,
        rpId: String,
        userId: Data,
    ) {
        self.counter = counter
        self.credentialId = credentialId
        self.hmacSecret = hmacSecret
        self.key = key
        self.rpId = rpId
        self.userId = userId
    }
}
