import Foundation

@testable import BitwardenShared

extension Organization {
    static func fixture(
        enabled: Bool = true,
        id: String = "organization-1",
        key: String? = nil,
        name: String = "",
        status: OrganizationUserStatusType = .confirmed,
        usersGetPremium: Bool = false
    ) -> Organization {
        Organization(
            enabled: enabled,
            id: id,
            key: key,
            name: name,
            status: status,
            usersGetPremium: usersGetPremium
        )
    }
}
