import Foundation
import Networking

// MARK: - AnswerLoginRequestRequest

/// A request for answering a login requests.
///
struct AnswerLoginRequestRequest: Request {
    typealias Response = LoginRequest

    // MARK: Properties

    /// The body of the request.
    var body: AnswerLoginRequestRequestModel? { requestModel }

    /// The id of the login request to answer.
    let id: String

    /// The HTTP method for this request.
    var method: HTTPMethod { .put }

    /// The URL path for this request.
    var path: String { "/auth-requests/\(id)" }

    /// The request details to include in the body of the request.
    let requestModel: AnswerLoginRequestRequestModel
}
