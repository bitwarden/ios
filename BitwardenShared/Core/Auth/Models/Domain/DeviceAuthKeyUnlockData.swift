import Foundation

// MARK: - DeviceAuthKeyUnlockData

/// The data needed to unlock the vault with the device auth key.
///
struct DeviceAuthKeyUnlockData: Equatable, Sendable {
    /// The private key of the PRF key set, encrypted with the key derived from `prfOutput`.
    let encryptedPrivateKey: String

    /// The user key, encapsulated with the public key of the PRF key set.
    let encryptedUserKey: String

    /// The base64 encoded PRF output of the device auth key.
    let prfOutput: String
}
