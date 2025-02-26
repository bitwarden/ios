import Networking
import XCTest

@testable import BitwardenShared

class DefaultHeadersRequestHandlerTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DefaultHeadersRequestHandler!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DefaultHeadersRequestHandler(
            appName: "Bitwarden",
            appVersion: "2023.8.0",
            buildNumber: "123",
            systemDevice: MockSystemDevice()
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `handle(_:)` applies default headers to requests.
    func test_handleRequest_addsDefaultHeaders() async throws {
        var request = HTTPRequest(url: URL(string: "https://example.com")!)

        let handledRequest = try await subject.handle(&request)

        XCTAssertEqual(handledRequest.headers["Bitwarden-Client-Name"], "mobile")
        XCTAssertEqual(handledRequest.headers["Bitwarden-Client-Version"], "2023.8.0")
        XCTAssertEqual(handledRequest.headers["Device-Type"], "1")
        XCTAssertEqual(handledRequest.headers["User-Agent"], "Bitwarden/2023.8.0 (iOS 16.4; Model iPhone)")
    }
}
