import Foundation
import Networking

// MARK: - SingleSignOnDomainsVerifiedRequest

/// A request for checking the single sign on domain verified for a user.
///
struct SingleSignOnDomainsVerifiedRequest: Request {
    typealias Response = SingleSignOnDomainsVerifiedResponse

    // MARK: Properties

    /// The body of the request.
    var body: SingleSignOnDomainsVerifiedRequestModel? {
        SingleSignOnDomainsVerifiedRequestModel(email: email)
    }

    /// The HTTP method for this request.
    var method: HTTPMethod { .post }

    /// The URL path for this request.
    var path: String { "/organizations/domain/sso/verified" }

    /// The email of the user to check the single sign on details for.
    let email: String
}
