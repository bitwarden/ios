import Networking

// MARK: - UpdatePasswordRequestModel

/// API request model for updating a user's password.
///
struct UpdatePasswordRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The user's key.
    let key: String

    /// The hash of the user's current master password.
    let masterPasswordHash: String?

    /// The master password hint.
    let masterPasswordHint: String

    /// The hash of the new master password.
    let newMasterPasswordHash: String
}
