import BitwardenKit
import Foundation

@testable import BitwardenShared

extension DeviceResponse {
    static func fixture(
        creationDate: Date = Date(timeIntervalSince1970: 1_704_067_200),
        id: String = "device-id-1",
        identifier: String = "device-identifier-1",
        isTrusted: Bool = true,
        lastActivityDate: Date? = Date(timeIntervalSince1970: 1_718_452_200),
        name: String? = "iPhone 15 Pro",
        type: DeviceType = .iOS,
    ) -> DeviceResponse {
        DeviceResponse(
            creationDate: creationDate,
            id: id,
            identifier: identifier,
            isTrusted: isTrusted,
            lastActivityDate: lastActivityDate,
            name: name,
            type: type,
        )
    }
}
