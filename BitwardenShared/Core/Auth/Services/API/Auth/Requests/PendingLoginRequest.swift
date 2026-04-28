import Foundation
import Networking

// MARK: - PendingLoginRequestError

/// Errors thrown from validating a `PendingLoginRequest` response.
enum PendingLoginRequestError: Error {
    /// The login request was not found (e.g., it expired before it could be answered).
    case notFound
}

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

    // MARK: Request

    func validate(_ response: HTTPResponse) throws {
        if response.statusCode == 404 {
            throw PendingLoginRequestError.notFound
        }
    }
}
