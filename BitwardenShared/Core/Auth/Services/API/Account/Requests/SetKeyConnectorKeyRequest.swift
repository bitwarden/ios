import Networking

// MARK: - SetKeyConnectorKeyRequest

/// The API request sent to set a user's key connector key.
///
struct SetKeyConnectorKeyRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The body of this request.
    var body: SetKeyConnectorKeyRequestModel?

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    let path: String = "/accounts/set-key-connector-key"

    // MARK: Initialization

    /// Creates a new `SetKeyConnectorKeyRequest` instance.
    ///
    /// - Parameter requestModel: The data model to send in the body of the request.
    ///
    init(requestModel: SetKeyConnectorKeyRequestModel) {
        body = requestModel
    }
}
