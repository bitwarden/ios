import BitwardenSdk

// MARK: - MasterPasswordAuthenticationDataRequestModel

/// A request model for a user's master password authentication data.
///
struct MasterPasswordAuthenticationDataRequestModel: Encodable, Equatable {
    // MARK: Properties

    /// The KDF settings.
    let kdf: KdfConfig

    /// The master password hash.
    let masterPasswordAuthenticationHash: String

    /// The salt used to compute the master password hash.
    let salt: String
}

extension MasterPasswordAuthenticationDataRequestModel {
    /// Initialize `MasterPasswordAuthenticationDataRequestModel` from `MasterPasswordAuthenticationData`.
    ///
    /// - Parameter authenticationData: The `MasterPasswordAuthenticationData` used to initialize a
    ///     `MasterPasswordAuthenticationDataRequestModel`.
    ///
    init(authenticationData: MasterPasswordAuthenticationData) {
        self.init(
            kdf: KdfConfig(kdf: authenticationData.kdf),
            masterPasswordAuthenticationHash: authenticationData.masterPasswordAuthenticationHash,
            salt: authenticationData.salt,
        )
    }
}
