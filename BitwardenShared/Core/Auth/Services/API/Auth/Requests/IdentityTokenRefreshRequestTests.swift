import XCTest

@testable import BitwardenShared

class IdentityTokenRefreshRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: IdentityTokenRefreshRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = IdentityTokenRefreshRequest(refreshToken: "REFRESH_TOKEN")
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` returns the URL encoded form data for the request.
    func test_body() throws {
        let bodyData = try XCTUnwrap(subject.body?.encode())
        XCTAssertEqual(
            String(data: bodyData, encoding: .utf8),
            "client%5Fid=mobile&grant%5Ftype=refresh%5Ftoken&refresh%5Ftoken=REFRESH%5FTOKEN"
        )
    }

    /// `query` returns no headers.
    func test_headers() {
        XCTAssertTrue(subject.headers.isEmpty)
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/connect/token")
    }

    /// `query` returns no query parameters.
    func test_query() {
        XCTAssertTrue(subject.query.isEmpty)
    }
}
