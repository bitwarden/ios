import XCTest

@testable import BitwardenShared

// MARK: - PreLoginRequestTests

class PreLoginRequestTests: BitwardenTestCase {
    // MARK: Tests

    /// `body` is `nil`.
    func test_body() {
        let body = PreLoginRequestBodyModel(email: "email@example.com")
        let subject = PreLoginRequest(body: body)
        XCTAssertEqual(body, subject.body)
    }

    /// `method` is `.get`.
    func test_method() {
        let subject = PreLoginRequest(body: PreLoginRequestBodyModel(email: ""))
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` is the correct value.
    func test_path() {
        let subject = PreLoginRequest(body: PreLoginRequestBodyModel(email: ""))
        XCTAssertEqual(subject.path, "/account/prelogin")
    }

    /// `query` is empty.
    func test_query() {
        let subject = PreLoginRequest(body: PreLoginRequestBodyModel(email: ""))
        XCTAssertTrue(subject.query.isEmpty)
    }
}
