import Networking

// MARK: - RemovePasswordFromSendRequest

/// A request to remove the password from a send.
///
struct RemovePasswordFromSendRequest: Request {
    // MARK: Types

    typealias Response = SendResponseModel

    // MARK: Properties

    /// The HTTP method for the request.
    let method: HTTPMethod = .put

    /// The URL path for this request that will be appended to the base URL.
    var path: String { "/sends/\(sendId)/remove-password" }

    /// The id of the Send to remove the password for.
    let sendId: String

    // MARK: Initialization

    /// Creates a new `RemovePasswordFromSendRequest`.
    ///
    /// - Parameter sendId: The id of the Send to be deleted.
    ///
    init(sendId: String) {
        self.sendId = sendId
    }
}
