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

    /// Validates decoding a `DeviceResponse`'s `devicePendingAuthRequest` when the server reports
    /// a pending authentication request directly on the device record.
    func test_decode_devicePendingAuthRequest() throws {
        let json = Data("""
        {
            "id": "device-id-1",
            "name": "chrome",
            "identifier": "device-identifier-1",
            "type": 9,
            "creationDate": "2024-01-01T00:00:00.000Z",
            "isTrusted": true,
            "lastActivityDate": null,
            "devicePendingAuthRequest": {
                "id": "72b50b5a-13e1-4300-b966-b49b00a2b1e4",
                "creationDate": "2026-08-03T09:52:21.240Z"
            }
        }
        """.utf8)
        let subject = try JSONDecoder.defaultDecoder.decode(DeviceResponse.self, from: json)

        var dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedCreationDate = try XCTUnwrap(dateFormatter.date(from: "2026-08-03T09:52:21.240Z"))

        XCTAssertEqual(subject.devicePendingAuthRequest?.id, "72b50b5a-13e1-4300-b966-b49b00a2b1e4")
        XCTAssertEqual(subject.devicePendingAuthRequest?.creationDate, expectedCreationDate)
    }

    /// Decoding a `DeviceResponse` defaults `devicePendingAuthRequest` to `nil` when the server
    /// doesn't report a pending authentication request for the device.
    func test_decode_devicePendingAuthRequest_nil() throws {
        let subject = try JSONDecoder.defaultDecoder.decode(
            DeviceResponse.self,
            from: APITestData.currentDevice.data,
        )
        XCTAssertNil(subject.devicePendingAuthRequest)
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
