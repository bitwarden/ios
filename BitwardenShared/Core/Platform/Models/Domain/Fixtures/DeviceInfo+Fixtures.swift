@testable import BitwardenShared

extension DeviceInfo {
    static func fixture(
        identifier: String = "1234",
        name: String = "iPhone 14",
        pushToken: String = "pushToken",
        type: DeviceType = .iOS
    ) -> DeviceInfo {
        DeviceInfo(
            identifier: identifier,
            name: name,
            pushToken: pushToken,
            type: type
        )
    }
}
