@testable import BitwardenShared

extension Policy {
    static func fixture(
        data: [String: AnyCodable]? = nil,
        enabled: Bool = true,
        id: String = "policy-1",
        organizationId: String = "organization-1",
        type: PolicyType = .twoFactorAuthentication
    ) -> Policy {
        Policy(
            data: data,
            enabled: enabled,
            id: id,
            organizationId: organizationId,
            type: type
        )
    }
}
