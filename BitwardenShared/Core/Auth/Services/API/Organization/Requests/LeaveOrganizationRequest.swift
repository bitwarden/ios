import Networking

// MARK: - LeaveOrganizationRequest

/// The API request sent for a user to leave an organization.
///
struct LeaveOrganizationRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The organization's ID.
    let organizationId: String

    /// The URL path for this request.
    var path: String { "/organizations/\(organizationId)/leave" }
}
