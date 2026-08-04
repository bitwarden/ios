import Foundation

@testable import BitwardenShared

extension DevicePendingAuthRequest {
    static func fixture(
        creationDate: Date = Date(timeIntervalSince1970: 1_704_067_200),
        id: String = "auth-request-id-1",
    ) -> DevicePendingAuthRequest {
        DevicePendingAuthRequest(
            creationDate: creationDate,
            id: id,
        )
    }
}
