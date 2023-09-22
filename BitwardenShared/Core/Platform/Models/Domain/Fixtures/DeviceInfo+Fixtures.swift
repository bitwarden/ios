@testable import BitwardenShared

extension DeviceInfo {
    static func fixture(
        identifier: String = "1234",
        name: String = "iPhone 14"
    ) -> DeviceInfo {
        DeviceInfo(
            identifier: identifier,
            name: name
        )
    }
}
