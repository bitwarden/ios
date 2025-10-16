import BitwardenSdk

// MARK: - MasterPasswordUnlockDataRequestModel

/// A request model for a user's unlock data.
///
struct MasterPasswordUnlockDataRequestModel: Encodable, Equatable {
    // MARK: Properties

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
            kdf: KdfConfig(kdf: unlockData.kdf),
            masterKeyWrappedUserKey: unlockData.masterKeyWrappedUserKey,
            salt: unlockData.salt,
        )
    }
}
