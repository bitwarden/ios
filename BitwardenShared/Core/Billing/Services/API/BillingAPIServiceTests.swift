import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

@MainActor
class BillingAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var stateService: MockStateService!
    var subject: BillingAPIService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        stateService = MockStateService()
        subject = APIService(client: client, stateService: stateService)
    }

    override func tearDown() async throws {
        try await super.tearDown()

        client = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `createCheckoutSession()` performs the request with the correct method, path, and body.
    func test_createCheckoutSession() async throws {
        client.result = .httpSuccess(testData: .checkoutSession)

        _ = try await subject.createCheckoutSession()

        let request = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url.absoluteString, "https://example.com/api/account/billing/vnext/premium/checkout")
        XCTAssertNotNil(request.body)

        let body = try XCTUnwrap(request.body)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        XCTAssertEqual(json?["platform"] as? String, "ios")
    }

    /// `getPortalUrl()` performs the request with the correct method and path.
    func test_getPortalUrl() async throws {
        client.result = .httpSuccess(testData: .portalUrl)

        _ = try await subject.getPortalUrl()

        let request = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url.absoluteString, "https://example.com/api/account/billing/vnext/portal-session")
        XCTAssertNil(request.body)
    }
}
