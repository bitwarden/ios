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

extension MasterPasswordUnlockResponseModel {
    /// Creates a `MasterPasswordUnlockResponseModel` from an `Account` and an encrypted user key.
    ///
    /// - Parameters:
    ///   - account: The account whose KDF configuration and email are used.
    ///   - masterKeyEncryptedUserKey: The user key encrypted with the master key.
    ///
    init(account: Account, masterKeyEncryptedUserKey: String) {
        self.init(
            kdf: account.kdf,
            masterKeyEncryptedUserKey: masterKeyEncryptedUserKey,
            salt: account.profile.email,
        )
    }
}
