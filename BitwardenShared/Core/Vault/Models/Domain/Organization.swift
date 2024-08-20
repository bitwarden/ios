/// A domain model containing the details of an organization.
///
public struct Organization: Equatable, Hashable {
    // MARK: Properties

    /// Whether the profile organization is enabled.
    let enabled: Bool

    /// The organization's identifier.
    let id: String

    /// The profile organization's key.
    let key: String?

    /// The key connector URL for the profile organization.
    let keyConnectorUrl: String?

    /// The organization's name.
    let name: String

    /// The profile organization's permissions.
    let permissions: Permissions

    /// The profile's organization's status.
    let status: OrganizationUserStatusType

    /// The profile's organization's type.
    let type: OrganizationUserType

    /// Whether the profile's organization uses events.
    let useEvents: Bool

    /// Whether the profile's organization uses key connector.
    let useKeyConnector: Bool

    /// Whether the profile's organization uses policies.
    let usePolicies: Bool

    /// Whether the profile organization's users get premium.
    let usersGetPremium: Bool
}

extension Organization {
    init?(responseModel: ProfileOrganizationResponseModel) {
        guard let name = responseModel.name else { return nil }
        self.init(
            enabled: responseModel.enabled,
            id: responseModel.id,
            key: responseModel.key,
            keyConnectorUrl: responseModel.keyConnectorUrl,
            name: name,
            permissions: responseModel.permissions ?? Permissions(),
            status: responseModel.status,
            type: responseModel.type,
            useEvents: responseModel.useEvents,
            useKeyConnector: responseModel.useKeyConnector,
            usePolicies: responseModel.usePolicies,
            usersGetPremium: responseModel.usersGetPremium
        )
    }

    init?(organizationData: OrganizationData) throws {
        guard let model = organizationData.model else {
            throw DataMappingError.invalidData
        }
        self.init(responseModel: model)
    }
}

extension Organization {
    /// Whether the user can manage policies for the organization.
    var canManagePolicies: Bool {
        isAdmin || permissions.managePolicies
    }

    /// Whether the user is an admin of the organization.
    var isAdmin: Bool {
        [OrganizationUserType.owner, OrganizationUserType.admin].contains(type)
    }

    /// Whether the user is exempt from policies.
    var isExemptFromPolicies: Bool {
        canManagePolicies
    }
}
