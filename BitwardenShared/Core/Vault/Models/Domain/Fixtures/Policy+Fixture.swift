import BitwardenKit
import Foundation
@testable import BitwardenShared

extension Policy {
    static func fixture(
        data: [String: AnyCodable]? = nil,
        enabled: Bool = true,
        id: String = "policy-1",
        organizationId: String = "organization-1",
        revisionDate: Date? = nil,
        type: PolicyType = .twoFactorAuthentication,
    ) -> Policy {
        Policy(
            data: data,
            enabled: enabled,
            id: id,
            organizationId: organizationId,
            revisionDate: revisionDate,
            type: type,
        )
    }
}
