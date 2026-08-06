import Foundation

@testable import BitwardenShared

extension Organization {
    static func fixture(
        enabled: Bool = true,
        id: String = "organization-1",
        isProviderUser: Bool = false,
        key: String? = nil,
        keyConnectorEnabled: Bool = false,
        keyConnectorUrl: String? = nil,
        name: String = "",
        permissions: Permissions = Permissions(),
        status: OrganizationUserStatusType = .confirmed,
        type: OrganizationUserType = .user,
        useEvents: Bool = false,
        usePolicies: Bool = true,
        userIsManagedByOrganization: Bool = false,
        usersGetPremium: Bool = false,
    ) -> Organization {
        Organization(
            enabled: enabled,
            id: id,
            isProviderUser: isProviderUser,
            key: key,
            keyConnectorEnabled: keyConnectorEnabled,
            keyConnectorUrl: keyConnectorUrl,
            name: name,
            permissions: permissions,
            status: status,
            type: type,
            useEvents: useEvents,
            usePolicies: usePolicies,
            userIsManagedByOrganization: userIsManagedByOrganization,
            usersGetPremium: usersGetPremium,
        )
    }
}
