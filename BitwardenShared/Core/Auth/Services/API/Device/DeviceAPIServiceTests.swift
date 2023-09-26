import XCTest

@testable import BitwardenShared

// MARK: - DeviceAPIServiceTests

class DeviceAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: APIService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        client = MockHTTPClient()
        subject = APIService(baseUrl: .example, client: client)
    }

    override func tearDown() {
        super.tearDown()
        client = nil
        subject = nil
    }

    // MARK: Tests

    /// `knownDevice(email:deviceIdentifier:)` returns the correct value from the API with a successful request.
    func test_knownDevice_success() async throws {
        let resultData = APITestData.knownDeviceTrue
        client.result = .httpSuccess(testData: resultData)

        let isKnownDevice = try await subject.knownDevice(
            email: "email@example.com",
            deviceIdentifier: "1234"
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
                deviceIdentifier: "1234"
            )
        }
    }

    /// `knownDevice(email:deviceIdentifier:)` throws an error if the request fails.
    func test_knownDevice_httpFailure() async {
        client.result = .httpFailure()

        await assertAsyncThrows {
            _ = try await subject.knownDevice(
                email: "email@example.com",
                deviceIdentifier: "1234"
            )
        }
    }
}
