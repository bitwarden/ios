/// An enum that describes the status of a user in an organization.
///
enum OrganizationUserStatusType: Int, Codable {
    /// The user has been invited.
    case invited = 0

    /// The user has accepted the invitation.
    case accepted = 1

    /// The user has been confirmed in the organization.
    case confirmed = 2

    /// The user has been provisioned but has not yet been invited.
    case staged = 3
}
