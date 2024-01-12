import Foundation
import Networking

// MARK: - SingleSignOnDetailsRequest

/// A request for checking the single sign on details for a user.
///
struct SingleSignOnDetailsRequest: Request {
    typealias Response = SingleSignOnDetailsResponse

    // MARK: Properties

    /// The body of the request.
    var body: SingleSignOnDetailsRequestModel? {
        SingleSignOnDetailsRequestModel(email: email)
    }

    /// The HTTP method for this request.
    var method: HTTPMethod { .post }

    /// The URL path for this request.
    var path: String { "/organizations/domain/sso/details" }

    /// The email of the user to check the single sign on details for.
    let email: String
}
