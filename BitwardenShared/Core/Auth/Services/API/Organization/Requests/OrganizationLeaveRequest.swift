import Networking

// MARK: - OrganizationLeaveRequest

/// A networking request to leave an organization.
struct OrganizationLeaveRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The identifier for the organization.
    let identifier: String

    /// The HTTP method for this request.
    var method: HTTPMethod { .post }

    /// The URL path for this request.
    var path: String { "/organizations/\(identifier)/leave" }
}
