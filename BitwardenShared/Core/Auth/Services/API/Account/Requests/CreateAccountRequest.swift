import Foundation
import Networking

// MARK: - CreateAccountError

/// Enumeration of errors that may occur when creating an account.
///
enum CreateAccountError: Error {
    /// The password was found in data breaches.
    case passwordBreachesFound
}

// MARK: - CreateAccountRequest

/// The API request sent when submitting an account creation form.
///
struct CreateAccountRequest: Request {
    typealias Response = CreateAccountResponseModel
    typealias Body = CreateAccountRequestModel

    /// The body of this request.
    var body: CreateAccountRequestModel?

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    var path: String = "/accounts/register"

    /// Creates a new `CreateAccountRequest` instance.
    ///
    /// - Parameter body: The body of the request.
    ///
    init(body: CreateAccountRequestModel) {
        self.body = body
    }
}
