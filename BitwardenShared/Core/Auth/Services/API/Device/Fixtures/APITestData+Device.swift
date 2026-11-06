import Foundation
import TestHelpers

// swiftlint:disable missing_docs

public extension APITestData {
    // MARK: Known Device

    static let knownDeviceTrue = APITestData(data: Data("true".utf8))
    static let knownDeviceFalse = APITestData(data: Data("false".utf8))

    // MARK: Current Device

    static let currentDevice = loadFromJsonBundle(resource: "CurrentDevice")

    // MARK: Devices List

    static let devicesList = loadFromJsonBundle(resource: "DevicesList")
}

// swiftlint:enable missing_docs
