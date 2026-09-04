import BitwardenSdk

// MARK: - MasterPasswordUnlockDataRequestModel

/// A request model for a user's unlock data.
///
struct MasterPasswordUnlockDataRequestModel: Encodable, Equatable {
    // MARK: Properties

    /// The ID of the key contained in `masterKeyWrappedUserKey`, when the user's key has one.
    let containedKeyId: String?

    /// The KDF settings.
    let kdf: KdfConfig

    /// The user's master key encrypted with their user key.
    let masterKeyWrappedUserKey: String

    /// The salt used to encrypt the user key.
    let salt: String
}

extension MasterPasswordUnlockDataRequestModel {
    /// Initialize `MasterPasswordUnlockDataRequestModel` from `MasterPasswordUnlockData`.
    ///
    /// - Parameter authenticationData: The `MasterPasswordUnlockData` used to initialize a
    ///     `MasterPasswordUnlockDataRequestModel`.
    ///
    init(unlockData: MasterPasswordUnlockData) {
        self.init(
            containedKeyId: unlockData.containedKeyId,
            kdf: KdfConfig(kdf: unlockData.kdf),
            masterKeyWrappedUserKey: unlockData.masterKeyWrappedUserKey,
            salt: unlockData.salt,
        )
    }
}
