import Foundation
import Networking

// MARK: - PendingLoginRequest

/// A request for getting a specific pending login request.
///
struct PendingLoginRequest: Request {
    typealias Response = LoginRequest

    // MARK: Properties

    /// The id of the request to get.
    var id: String

    /// The HTTP method for this request.
    var method: HTTPMethod { .get }

    /// The URL path for this request.
    var path: String { "/auth-requests/\(id)" }
}
