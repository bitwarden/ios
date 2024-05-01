import XCTest

@testable import BitwardenShared

class ConfigAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: ConfigAPIService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        subject = APIService(client: client)
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        subject = nil
    }

    // MARK: Tests

    /// `getConfig()` performs the config request.
    func test_getConfig() async throws {
        client.result = .httpSuccess(testData: .validServerConfig)

        _ = try await subject.getConfig()

        let request = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.absoluteString, "https://example.com/api/config")
        XCTAssertNil(request.body)
    }
}
