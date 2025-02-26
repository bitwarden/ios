import XCTest

@testable import BitwardenShared

// MARK: - PreLoginRequestTests

class PreLoginRequestTests: BitwardenTestCase {
    // MARK: Tests

    /// `body` is the value passed into the initializer.
    func test_body() {
        let body = PreLoginRequestModel(email: "email@example.com")
        let subject = PreLoginRequest(body: body)
        XCTAssertEqual(body, subject.body)
    }

    /// `method` is `.post`.
    func test_method() {
        let subject = PreLoginRequest(body: PreLoginRequestModel(email: ""))
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` is the correct value.
    func test_path() {
        let subject = PreLoginRequest(body: PreLoginRequestModel(email: ""))
        XCTAssertEqual(subject.path, "/accounts/prelogin")
    }

    /// `query` is empty.
    func test_query() {
        let subject = PreLoginRequest(body: PreLoginRequestModel(email: ""))
        XCTAssertTrue(subject.query.isEmpty)
    }
}
