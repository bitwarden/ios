import Foundation

// MARK: - DeviceAuthKeyUnlockData

/// The data needed to unlock the vault with the device auth key.
///
/// The PRF key set that the SDK registers with the device auth key uses the same wrapping as the
/// trusted device keys: a symmetric key encrypts a private key, and the matching public key
/// encapsulates the user key. This lets the app unlock with `InitUserCryptoMethod.deviceKey`.
///
struct DeviceAuthKeyUnlockData: Equatable, Sendable {
    /// The private key of the PRF key set, encrypted with `prfKey`.
    let encryptedPrivateKey: String

    /// The user key, encapsulated with the public key of the PRF key set.
    let encryptedUserKey: String

    /// The base64 encoded 64-byte symmetric key (encryption key + MAC key) stretched from the
    /// device auth key's PRF output.
    let prfKey: String
}
