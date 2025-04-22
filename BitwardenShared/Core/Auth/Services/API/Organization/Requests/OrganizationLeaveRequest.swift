import Networking

// MARK: - OrganizationAutoEnrollStatusRequest

/// A networking request to get the auto-enroll status for an organization.
///
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
