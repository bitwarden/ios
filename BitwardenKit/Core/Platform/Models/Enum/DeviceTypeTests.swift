import BitwardenKit
import XCTest

class DeviceTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `defaultValue` returns the default value for the type if an invalid or missing value is
    /// received when decoding the type.
    func test_defaultValue() {
        XCTAssertEqual(DeviceType.defaultValue, .unknownBrowser)
    }
}
