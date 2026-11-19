import Networking

// MARK: - UpdatePasswordRequestModel

/// API request model for updating a user's password.
///
struct UpdatePasswordRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The new password's authentication data.
    let authenticationData: MasterPasswordAuthenticationDataRequestModel

    /// The hash of the user's current master password.
    let masterPasswordHash: String?

    /// The master password hint.
    let masterPasswordHint: String

    /// The new password's unlock data.
    let unlockData: MasterPasswordUnlockDataRequestModel
}
