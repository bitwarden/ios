import Networking
import XCTest

@testable import BitwardenShared

class GetPortalUrlRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: GetPortalUrlRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = GetPortalUrlRequest()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` returns `nil`.
    func test_body() throws {
        XCTAssertNil(subject.body)
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/account/billing/vnext/portal-session")
    }
}
