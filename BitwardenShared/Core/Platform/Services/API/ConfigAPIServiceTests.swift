import XCTest

@testable import BitwardenShared

class ConfigAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var stateService: MockStateService!
    var subject: ConfigAPIService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        stateService = MockStateService()
        subject = APIService(client: client, stateService: stateService)
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `getConfig()` performs the config request authenticated.
    func test_getConfig() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.isAuthenticated[account.profile.userId] = true
        client.result = .httpSuccess(testData: .validServerConfig)

        _ = try await subject.getConfig()

        let request = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.absoluteString, "https://example.com/api/config")
        XCTAssertNil(request.body)
        XCTAssertNotNil(request.headers["Authorization"])
    }

    /// `getConfig()` performs the config request unauthenticated.
    func test_getConfig_unauthenticated() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.isAuthenticated[account.profile.userId] = false
        client.result = .httpSuccess(testData: .validServerConfig)

        _ = try await subject.getConfig()

        let request = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.absoluteString, "https://example.com/api/config")
        XCTAssertNil(request.body)
        XCTAssertNil(request.headers["Authorization"])
    }

    /// `getConfig()` performs the config request unauthenticated because there is no active account.
    func test_getConfig_unauthenticatedNoAccount() async throws {
        client.result = .httpSuccess(testData: .validServerConfig)

        _ = try await subject.getConfig()

        let request = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.absoluteString, "https://example.com/api/config")
        XCTAssertNil(request.body)
        XCTAssertNil(request.headers["Authorization"])
    }
}
