import Networking

// MARK: - UpdateKdfRequestModel

/// The request body for an update KDF request.
///
struct UpdateKdfRequestModel: JSONRequestBody, Equatable {
    // MARK: Properties

    /// The user's data for authentication.
    let authenticationData: MasterPasswordAuthenticationDataRequestModel

    /// The user's key.
    let key: String

    /// The hash of the old master password.
    let masterPasswordHash: String

    /// The hash of the new master password.
    let newMasterPasswordHash: String

    /// The user's data for unlock.
    let unlockData: MasterPasswordUnlockDataRequestModel
}
