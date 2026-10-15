import Networking

// MARK: - UpdateTempPasswordRequestModel

/// API request model for updating a user's temporary password.
///
struct UpdateTempPasswordRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The new password's authentication data.
    let authenticationData: MasterPasswordAuthenticationDataRequestModel

    /// The master password hint.
    let masterPasswordHint: String

    /// The new password's unlock data.
    let unlockData: MasterPasswordUnlockDataRequestModel
}
