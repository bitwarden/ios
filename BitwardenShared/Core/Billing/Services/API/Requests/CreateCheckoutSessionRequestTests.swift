import Networking
import XCTest

@testable import BitwardenShared

class CreateCheckoutSessionRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: CreateCheckoutSessionRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = CreateCheckoutSessionRequest(
            requestModel: CheckoutSessionRequestModel(platform: "ios"),
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` returns the request model.
    func test_body() throws {
        let body = try XCTUnwrap(subject.body)
        XCTAssertEqual(body.platform, "ios")
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/account/billing/vnext/premium/checkout")
    }
}
