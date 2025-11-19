import Networking
import TestHelpers
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
            "client%5Fid=mobile&grant%5Ftype=refresh%5Ftoken&refresh%5Ftoken=REFRESH%5FTOKEN",
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

    /// `validate(_:)` with a valid response does not throw a validation error.
    func test_validate_with200() {
        let response = HTTPResponse.success(
            body: APITestData.identityTokenRefresh.data,
        )

        XCTAssertNoThrow(try subject.validate(response))
    }

    /// `validate(_:)` with a `400` status code and non invalid grant in the response body
    /// doesn't throw an error.
    func test_validate_with400DoesntThrow() {
        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.identityTokenRefreshStubError.data,
        )

        XCTAssertNoThrow(try subject.validate(response))
    }

    /// `validate(_:)` with a `400` status code and invalid grant in the response body throws a
    /// `.invalidGrant` error.
    func test_validate_with400InvalidGrantError() {
        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.identityTokenRefreshInvalidGrantError.data,
        )

        XCTAssertThrowsError(try subject.validate(response)) { error in
            XCTAssertEqual(error as? IdentityTokenRefreshRequestError, .invalidGrant)
        }
    }

    /// `query` returns no query parameters.
    func test_query() {
        XCTAssertTrue(subject.query.isEmpty)
    }
}
