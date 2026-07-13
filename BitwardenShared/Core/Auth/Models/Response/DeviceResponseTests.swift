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

    /// Decoding a `DeviceResponse` defaults `type` to `.unknownBrowser` when the server sends a
    /// raw value not yet recognized by the client.
    func test_decode_unknownType() throws {
        let json = Data("""
        {
            "id": "device-id-1",
            "name": "iPhone 15 Pro",
            "identifier": "device-identifier-1",
            "type": 999,
            "creationDate": "2024-01-01T00:00:00.000Z",
            "isTrusted": true,
            "lastActivityDate": null
        }
        """.utf8)
        let subject = try JSONDecoder.defaultDecoder.decode(DeviceResponse.self, from: json)
        XCTAssertEqual(subject.type, .unknownBrowser)
    }
}
