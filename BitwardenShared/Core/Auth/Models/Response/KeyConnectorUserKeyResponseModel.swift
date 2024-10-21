import Networking

// MARK: - KeyConnectorUserKeyResponseModel

/// The response returned from the API when fetching the user's key from the key connector API.
///
struct KeyConnectorUserKeyResponseModel: JSONResponse {
    // MARK: Properties

    /// The user's key.
    let key: String
}
