@testable import BitwardenShared

extension PolicyResponseModel {
    static func fixture(
        data: [String: AnyCodable]? = nil,
        enabled: Bool = true,
        id: String = "policy-1",
        organizationId: String = "org-1",
        type: PolicyType = .twoFactorAuthentication
    ) -> PolicyResponseModel {
        PolicyResponseModel(
            data: data,
            enabled: enabled,
            id: id,
            organizationId: organizationId,
            type: type
        )
    }
}
