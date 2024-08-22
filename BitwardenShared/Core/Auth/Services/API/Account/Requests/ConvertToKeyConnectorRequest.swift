import Networking

// MARK: - ConvertToKeyConnectorRequest

/// The API request sent to convert a user's account to use key connector.
///
struct ConvertToKeyConnectorRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    let path: String = "/accounts/convert-to-key-connector"
}
