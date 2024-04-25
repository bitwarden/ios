import Networking
import XCTest

@testable import BitwardenShared

class CheckLoginRequestRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: CheckLoginRequestRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = CheckLoginRequestRequest(accessCode: "ACCESS_CODE", id: "ID")
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .get)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/auth-requests/ID/response")
    }

    /// `query` returns the query items of the request.
    func test_query() {
        XCTAssertEqual(subject.query, [URLQueryItem(name: "code", value: "ACCESS_CODE")])
    }

    /// `validate(_:)` validates the response for the request and throws an error if the request is expired.
    func test_validate() {
        XCTAssertNoThrow(try subject.validate(.success()))
        XCTAssertNoThrow(try subject.validate(.failure(statusCode: 400)))
        XCTAssertNoThrow(try subject.validate(.failure(statusCode: 500)))

        XCTAssertThrowsError(try subject.validate(.failure(statusCode: 404))) { error in
            XCTAssertEqual(error as? CheckLoginRequestError, .expired)
        }
    }
}
