import XCTest

@testable import BitwardenShared

// MARK: - CreateAccountRequestTests

class CreateAccountRequestTests: BitwardenTestCase {
    /// Validate that the method is correct.
    func test_method() {
        let subject = CreateAccountRequest(
            body: CreateAccountRequestModel(
                email: "email@example.com",
                masterPasswordHash: "1234"
            )
        )
        XCTAssertEqual(subject.method, .post)
    }

    /// Validate that the path is correct.
    func test_path() {
        let subject = CreateAccountRequest(
            body: CreateAccountRequestModel(
                email: "email@example.com",
                masterPasswordHash: "1234"
            )
        )
        XCTAssertEqual(subject.path, "/accounts/register")
    }

    /// Validate that the body is not nil.
    func test_body() {
        let subject = CreateAccountRequest(
            body: CreateAccountRequestModel(
                email: "email@example.com",
                masterPasswordHash: "1234"
            )
        )
        XCTAssertNotNil(subject.body)
    }

    // MARK: Init

    /// Validate that the value provided to the init method is correct.
    func test_init_body() {
        let subject = CreateAccountRequest(
            body: CreateAccountRequestModel(
                email: "email@example.com",
                masterPasswordHash: "1234"
            )
        )
        XCTAssertEqual(subject.body?.email, "email@example.com")
        XCTAssertEqual(subject.body?.masterPasswordHash, "1234")
    }
}
