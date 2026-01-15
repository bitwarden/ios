import Networking

// MARK: - OrganizationRevokeSelfRequest

/// A networking request to revoke the current user's access to an organization.
struct OrganizationRevokeSelfRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The identifier for the organization.
    let organizationId: String

    /// The HTTP method for this request.
    var method: HTTPMethod { .put }

    /// The URL path for this request.
    var path: String { "/organizations/\(organizationId)/users/revoke-self" }
}
