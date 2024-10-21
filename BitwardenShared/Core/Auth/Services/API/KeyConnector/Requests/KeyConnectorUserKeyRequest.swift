import Networking

// MARK: - KeyConnectorUserKeyRequest

/// The API request sent when getting the user's key from the key connector API.
///
struct KeyConnectorUserKeyRequest: Request {
    typealias Response = KeyConnectorUserKeyResponseModel

    // MARK: Properties

    /// The HTTP method for this request.
    let method: HTTPMethod = .get

    /// The URL path for this request.
    let path: String = "/user-keys"
}
