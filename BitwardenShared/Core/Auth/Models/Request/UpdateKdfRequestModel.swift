import BitwardenSdk
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

extension UpdateKdfRequestModel {
    /// Initialize `UpdateKdfRequestModel` from `UpdateKdfResponse`.
    ///
    /// - Parameter response: The `UpdateKdfResponse` used to initialize a `UpdateKdfRequestModel`.
    ///
    init(response: UpdateKdfResponse) {
        self.init(
            authenticationData: MasterPasswordAuthenticationDataRequestModel(
                authenticationData: response.masterPasswordAuthenticationData,
            ),
            key: response.masterPasswordUnlockData.masterKeyWrappedUserKey,
            masterPasswordHash: response.oldMasterPasswordAuthenticationData.masterPasswordAuthenticationHash,
            newMasterPasswordHash: response.masterPasswordAuthenticationData.masterPasswordAuthenticationHash,
            unlockData: MasterPasswordUnlockDataRequestModel(
                unlockData: response.masterPasswordUnlockData,
            ),
        )
    }
}
