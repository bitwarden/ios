import Foundation
import Networking

// MARK: - CheckLoginRequestRequest

/// A request for checking the status of a login request for an unauthenticated user.
///
struct CheckLoginRequestRequest: Request {
    typealias Response = LoginRequest

    // MARK: Properties

    /// The access code generated when creating the request.
    var accessCode: String

    /// The id of the request to get.
    var id: String

    /// The HTTP method for this request.
    var method: HTTPMethod { .get }

    /// The URL path for this request.
    var path: String { "/auth-requests/\(id)/response" }

    /// The query item for this request.
    var query: [URLQueryItem] { [URLQueryItem(name: "code", value: accessCode)] }
}
