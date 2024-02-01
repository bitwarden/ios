import Networking

// MARK: - UpdateTempPasswordRequestModel

/// API request model for updating a user's temporary password.
///
struct UpdateTempPasswordRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The user's key.
    let key: String

    /// The master password hint.
    let masterPasswordHint: String

    /// The hash of the new master password.
    let newMasterPasswordHash: String
}
