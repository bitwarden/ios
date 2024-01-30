/// An enum that describes the type of a user in an organization.
///
enum OrganizationUserType: Int, Codable {
    /// The user is an owner of the organization.
    case owner = 0

    /// The user is an admin of the organization.
    case admin = 1

    /// The user is a user in the organization.
    case user = 2

    /// The user is a manage in the organization.
    case manager = 3

    /// The user is a custom user in the organization.
    case custom = 4
}
