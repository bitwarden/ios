import Foundation
import Networking

// MARK: - DeleteSendRequest

/// A request to delete a send.
///
struct DeleteSendRequest: Request {
    // MARK: Types

    typealias Response = EmptyResponse

    // MARK: Properties

    /// The HTTP method for the request.
    let method: HTTPMethod = .delete

    /// The URL path for this request that will be appended to the base URL.
    var path: String { "/sends/\(sendId)" }

    /// The id of the Send to be deleted.
    let sendId: String

    // MARK: Initialization

    /// Creates a new `DeleteSendRequest`.
    ///
    /// - Parameter sendId: The id of the Send to be deleted.
    init(sendId: String) {
        self.sendId = sendId
    }
}
