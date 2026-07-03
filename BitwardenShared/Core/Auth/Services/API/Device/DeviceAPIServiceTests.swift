import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - DeviceAPIServiceTests

@MainActor
class DeviceAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: APIService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        client = MockHTTPClient()
        subject = APIService(client: client)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        client = nil
        subject = nil
    }

    // MARK: Tests

    /// `getCurrentDevice(appId:)` returns the correct device from the API with a successful request.
    func test_getCurrentDevice_success() async throws {
        client.result = .httpSuccess(testData: .currentDevice)

        let device = try await subject.getCurrentDevice(appId: "app-id-123")

        let request = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.relativePath, "/api/devices/identifier/app-id-123")
        XCTAssertNil(request.body)

        XCTAssertEqual(device.id, "device-id-1")
        XCTAssertEqual(device.identifier, "device-identifier-1")
        XCTAssertEqual(device.type, .iOS)
        XCTAssertTrue(device.isTrusted)
    }

    /// `getCurrentDevice(appId:)` throws an error if the request fails.
    func test_getCurrentDevice_httpFailure() async {
        client.result = .httpFailure()

        await assertAsyncThrows {
            _ = try await subject.getCurrentDevice(appId: "app-id-123")
        }
    }

    /// `getDevices()` returns the correct list of devices from the API with a successful request.
    func test_getDevices_success() async throws {
        client.result = .httpSuccess(testData: .devicesList)

        let devices = try await subject.getDevices()

        let request = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.relativePath, "/api/devices")
        XCTAssertNil(request.body)

        XCTAssertEqual(devices.count, 2)
        XCTAssertEqual(devices[0].id, "device-id-1")
        XCTAssertTrue(devices[0].isTrusted)
        XCTAssertEqual(devices[1].id, "device-id-2")
        XCTAssertFalse(devices[1].isTrusted)
        XCTAssertNil(devices[1].lastActivityDate)
    }

    /// `getDevices()` throws an error if the request fails.
    func test_getDevices_httpFailure() async {
        client.result = .httpFailure()

        await assertAsyncThrows {
            _ = try await subject.getDevices()
        }
    }

    /// `knownDevice(email:deviceIdentifier:)` returns the correct value from the API with a successful request.
    func test_knownDevice_success() async throws {
        let resultData = APITestData.knownDeviceTrue
        client.result = .httpSuccess(testData: resultData)

        let isKnownDevice = try await subject.knownDevice(
            email: "email@example.com",
            deviceIdentifier: "1234",
        )

        let request = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.relativePath, "/api/devices/knowndevice")
        XCTAssertNil(request.body)
        XCTAssertEqual(request.headers["X-Request-Email"], "ZW1haWxAZXhhbXBsZS5jb20")
        XCTAssertEqual(request.headers["X-Device-Identifier"], "1234")

        XCTAssertTrue(isKnownDevice)
    }

    /// `knownDevice(email:deviceIdentifier:)` throws a decoding error if the response is not the expected type.
    func test_knownDevice_decodingFailure() async throws {
        let resultData = APITestData(data: Data("this should fail".utf8))
        client.result = .httpSuccess(testData: resultData)

        await assertAsyncThrows {
            _ = try await subject.knownDevice(
                email: "email@example.com",
                deviceIdentifier: "1234",
            )
        }
    }

    /// `knownDevice(email:deviceIdentifier:)` throws an error if the request fails.
    func test_knownDevice_httpFailure() async {
        client.result = .httpFailure()

        await assertAsyncThrows {
            _ = try await subject.knownDevice(
                email: "email@example.com",
                deviceIdentifier: "1234",
            )
        }
    }
}
