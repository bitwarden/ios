import Networking

// MARK: - PostKeyConnectorUserKeyRequest

/// The API request sent when sending the user's key to the key connector API.
///
struct PostKeyConnectorUserKeyRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The body of this request.
    var body: PostKeyConnectorUserKeyRequestModel?

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    let path: String = "/user-keys"

    // MARK: Initialization

    /// Creates a new `PostKeyConnectorUserKeyRequest` instance.
    ///
    /// - Parameter body: The body of the request.
    ///
    init(body: PostKeyConnectorUserKeyRequestModel) {
        self.body = body
    }
}
