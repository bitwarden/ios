import Foundation
import Networking

// MARK: - PendingLoginsRequest

/// A request for getting the pending login requests.
///
struct PendingLoginsRequest: Request {
    typealias Response = PendingLoginsResponse

    // MARK: Properties

    /// The HTTP method for this request.
    var method: HTTPMethod { .get }

    /// The URL path for this request.
    var path: String { "/auth-requests" }
}
