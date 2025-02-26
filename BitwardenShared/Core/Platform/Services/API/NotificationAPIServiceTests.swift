import XCTest

@testable import BitwardenShared

class NotificationAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: NotificationAPIService!

    // MARK: Set Up & Tear Down

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

    /// `savePushNotificationToken(for:token:)` performs the save push notification request.
    func test_savePushNotificationToken() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        _ = try await subject.savePushNotificationToken(for: "appId", token: "token")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .put)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/devices/identifier/appId/token")
    }
}
