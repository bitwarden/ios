import Foundation

@testable import BitwardenShared

extension ProfileOrganizationResponseModel {
    static func fixture(
        enabled: Bool = true,
        id: String = "profile-organization-1",
        identifier: String? = nil,
        key: String? = nil,
        keyConnectorEnabled: Bool = false,
        keyConnectorUrl: String? = nil,
        name: String? = "",
        permissions: Permissions? = nil,
        status: OrganizationUserStatusType = .confirmed,
        type: OrganizationUserType = .user,
        useEvents: Bool = false,
        usePolicies: Bool = false,
        userIsManagedByOrganization: Bool = false,
        usersGetPremium: Bool = false,
    ) -> ProfileOrganizationResponseModel {
        self.init(
            enabled: enabled,
            id: id,
            identifier: identifier,
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
