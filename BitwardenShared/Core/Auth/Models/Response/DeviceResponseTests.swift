import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - DeviceResponseTests

class DeviceResponseTests: BitwardenTestCase {
    // MARK: Decoding

    /// Validates decoding a `DeviceResponse` from the `CurrentDevice.json` fixture.
    func test_decode() throws {
        let subject = try JSONDecoder.defaultDecoder.decode(
            DeviceResponse.self,
            from: APITestData.currentDevice.data,
        )
        XCTAssertEqual(subject.id, "device-id-1")
        XCTAssertEqual(subject.identifier, "device-identifier-1")
        XCTAssertEqual(subject.name, "iPhone 15 Pro")
        XCTAssertEqual(subject.type, .iOS)
        XCTAssertTrue(subject.isTrusted)
        XCTAssertNotNil(subject.lastActivityDate)
    }
}
