import Networking

// MARK: - PostKeyConnectorUserKeyRequestModel

/// API request model for sending a user's key to the key connector API.
///
struct PostKeyConnectorUserKeyRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The user's key.
    let key: String
}
