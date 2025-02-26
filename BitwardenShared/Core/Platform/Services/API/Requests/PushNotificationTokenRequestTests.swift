import XCTest

@testable import BitwardenShared

class PushNotificationTokenRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: PushNotificationTokenRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = PushNotificationTokenRequest(appId: "getAnId", requestBody: .init(pushToken: "token"))
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `body` returns the  data for the request.
    func test_body() throws {
        let bodyData = try XCTUnwrap(subject.body?.encode())
        XCTAssertEqual(
            String(data: bodyData, encoding: .utf8),
            "{\"pushToken\":\"token\"}"
        )
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .put)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/devices/identifier/getAnId/token")
    }
}
