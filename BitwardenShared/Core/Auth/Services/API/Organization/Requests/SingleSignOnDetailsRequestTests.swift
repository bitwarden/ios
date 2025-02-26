import Networking
import XCTest

@testable import BitwardenShared

class SingleSignOnDetailsRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: SingleSignOnDetailsRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = SingleSignOnDetailsRequest(email: "email@example.com")
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `body` returns the body of the request.
    func test_body() throws {
        let bodyData = try XCTUnwrap(subject.body?.encode())
        XCTAssertEqual(
            String(data: bodyData, encoding: .utf8),
            "{\"email\":\"email@example.com\"}"
        )
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/organizations/domain/sso/details")
    }
}
