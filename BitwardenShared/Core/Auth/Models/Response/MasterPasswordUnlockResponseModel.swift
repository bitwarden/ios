// MARK: - MasterPasswordUnlockResponseModel

/// API response model for master password unlock information.
///
struct MasterPasswordUnlockResponseModel: Codable, Equatable, Hashable {
    // MARK: Properties

    /// The user's KDF configuration for master password unlock.
    let kdf: KdfConfig

    /// The user's encrypted user key, encrypted with the master key.
    let masterKeyEncryptedUserKey: String

    /// The cryptographic salt used in key derivation.
    let salt: String
}
