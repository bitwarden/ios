import BitwardenKit
import Foundation

/// API response model for a profile organization.
///
struct ProfileOrganizationResponseModel: Codable, Equatable {
    // MARK: Properties

    /// Whether the profile organization is enabled.
    let enabled: Bool

    /// The profile organization's identifier.
    let id: String

    /// The profile organization's identifier.
    let identifier: String?

    /// The profile organization's key.
    let key: String?

    /// Whether key connector is enabled for the profile organization.
    let keyConnectorEnabled: Bool

    /// The key connector URL for the profile organization.
    let keyConnectorUrl: String?

    /// The profile organization's name.
    let name: String?

    /// The profile organization's permissions.
    let permissions: Permissions?

    /// The profile's organization's status.
    let status: OrganizationUserStatusType

    /// The profile's organization's type.
    let type: OrganizationUserType

    /// Whether the profile organization uses events.
    let useEvents: Bool

    /// Whether the profile organization uses policies.
    let usePolicies: Bool

    /// Whether the user is managed by an organization.
    /// A user is considered managed by an organization if their email domain
    /// matches one of the verified domains of that organization, and the user is a member of it.
    @DefaultFalse var userIsManagedByOrganization: Bool

    /// Whether the profile organization's users get premium.
    let usersGetPremium: Bool
}

extension ProfileOrganizationResponseModel {
    // MARK: Computed Properties

    /// Whether the user can manage policies for the organization.
    var passwordRequired: Bool {
        type == OrganizationUserType.admin ||
            type == OrganizationUserType.owner ||
            permissions?.manageResetPassword == true
    }
}
