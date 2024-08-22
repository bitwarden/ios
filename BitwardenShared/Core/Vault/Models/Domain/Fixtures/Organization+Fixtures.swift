import Foundation

@testable import BitwardenShared

extension Organization {
    static func fixture(
        enabled: Bool = true,
        id: String = "organization-1",
        key: String? = nil,
        keyConnectorUrl: String? = nil,
        name: String = "",
        permissions: Permissions = Permissions(),
        status: OrganizationUserStatusType = .confirmed,
        type: OrganizationUserType = .user,
        useEvents: Bool = false,
        useKeyConnector: Bool = false,
        usePolicies: Bool = true,
        usersGetPremium: Bool = false
    ) -> Organization {
        Organization(
            enabled: enabled,
            id: id,
            key: key,
            keyConnectorUrl: keyConnectorUrl,
            name: name,
            permissions: permissions,
            status: status,
            type: type,
            useEvents: useEvents,
            useKeyConnector: useKeyConnector,
            usePolicies: usePolicies,
            usersGetPremium: usersGetPremium
        )
    }
}
