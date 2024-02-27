import Networking

// MARK: - OrganizationKeysRequest

/// A networking request to get the keys for an organization.
///
struct OrganizationKeysRequest: Request {
    typealias Response = OrganizationKeysResponseModel

    // MARK: Properties

    /// The organization's ID.
    let id: String

    /// The HTTP method for this request.
    var method: HTTPMethod { .get }

    /// The URL path for this request.
    var path: String { "/organizations/\(id)/keys" }
}
