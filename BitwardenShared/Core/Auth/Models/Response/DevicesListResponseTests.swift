import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - DevicesListResponseTests

class DevicesListResponseTests: BitwardenTestCase {
    // MARK: Decoding

    /// Validates decoding a `DevicesListResponse` from the `DevicesList.json` fixture.
    func test_decode() throws {
        let subject = try JSONDecoder.defaultDecoder.decode(
            DevicesListResponse.self,
            from: APITestData.devicesList.data,
        )
        XCTAssertEqual(subject.data.count, 2)

        let first = subject.data[0]
        XCTAssertEqual(first.id, "device-id-1")
        XCTAssertEqual(first.identifier, "device-identifier-1")
        XCTAssertEqual(first.name, "iPhone 15 Pro")
        XCTAssertEqual(first.type, .iOS)
        XCTAssertTrue(first.isTrusted)
        XCTAssertNotNil(first.lastActivityDate)

        let second = subject.data[1]
        XCTAssertEqual(second.id, "device-id-2")
        XCTAssertEqual(second.type, .chromeExtension)
        XCTAssertFalse(second.isTrusted)
        XCTAssertNil(second.lastActivityDate)
    }
}
