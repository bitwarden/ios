import Foundation
import Networking

// MARK: - PreValidateSingleSignOnRequest

/// A request for pre-validating the single-sign on for the specified organization identifier.
struct PreValidateSingleSignOnRequest: Request {
    typealias Response = PreValidateSingleSignOnResponse

    // MARK: Properties

    /// The HTTP method for this request.
    var method: HTTPMethod { .get }

    /// The organization identifier.
    let organizationIdentifier: String

    /// The URL path for this request.
    var path: String { "/sso/prevalidate" }

    /// The query items for this request.
    var query: [URLQueryItem] { [URLQueryItem(name: "domainHint", value: organizationIdentifier)] }
}
