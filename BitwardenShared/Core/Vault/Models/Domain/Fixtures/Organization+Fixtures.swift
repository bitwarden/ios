import Foundation

@testable import BitwardenShared

extension Organization {
    static func fixture(
        enabled: Bool = true,
        id: String = "organization-1",
        key: String? = nil,
        name: String = "",
        permissions: Permissions = Permissions(),
        status: OrganizationUserStatusType = .confirmed,
        type: OrganizationUserType = .user,
        usePolicies: Bool = true,
        usersGetPremium: Bool = false
    ) -> Organization {
        Organization(
            enabled: enabled,
            id: id,
            key: key,
            name: name,
            permissions: permissions,
            status: status,
            type: type,
            usePolicies: usePolicies,
            usersGetPremium: usersGetPremium
        )
    }
}
