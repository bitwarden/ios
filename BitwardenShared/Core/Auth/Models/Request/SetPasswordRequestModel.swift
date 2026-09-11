import Networking

// MARK: - SetPasswordRequestModel

/// API request model for settings a user's password.
///
struct SetPasswordRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The user's encryption keys.
    let keys: KeysRequestModel?

    /// The user's master password authentication data.
    let masterPasswordAuthentication: MasterPasswordAuthenticationDataRequestModel

    /// The master password hint.
    let masterPasswordHint: String?

    /// The user's master password unlock data.
    let masterPasswordUnlock: MasterPasswordUnlockDataRequestModel

    /// The organization's identifier.
    let orgIdentifier: String
}
