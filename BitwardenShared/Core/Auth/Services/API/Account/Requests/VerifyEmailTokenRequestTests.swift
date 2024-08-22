import Networking
import XCTest

@testable import BitwardenShared

// MARK: - VerifyEmailTokenRequestTests

class VerifyEmailTokenRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: VerifyEmailTokenRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = VerifyEmailTokenRequest(
            requestModel: VerifyEmailTokenRequestModel(
                email: "example@email.com",
                emailVerificationToken: "email-verification-token"
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// Validate that the method is correct.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// Validate that the path is correct.
    func test_path() {
        XCTAssertEqual(subject.path, "/accounts/register/verification-email-clicked")
    }

    /// Validate that the body is not nil.
    func test_body() {
        XCTAssertNotNil(subject.body)
    }

    /// `validate(_:)` with a `400` status code and an expired link error in the response body
    /// throws an `.tokenExpired` error.
    func test_validate_with400ExpiredLink() throws {
        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.verifyEmailTokenExpiredLink.data
        )

        XCTAssertThrowsError(try subject.validate(response)) { error in
            XCTAssertEqual(
                error as? VerifyEmailTokenRequestError,
                .tokenExpired
            )
        }
    }

    /// `validate(_:)` with a `400` status code but no captcha error does not throw a validation error.
    func test_validate_with400() {
        let response = HTTPResponse.failure(
            statusCode: 400,
            body: Data("example data".utf8)
        )

        XCTAssertNoThrow(try subject.validate(response))
    }

    /// `validate(_:)` with a valid response does not throw a validation error.
    func test_validate_with200() {
        let response = HTTPResponse.success()

        XCTAssertNoThrow(try subject.validate(response))
    }

    // MARK: Init

    /// Validate that the value provided to the init method is correct.
    func test_init_body() {
        XCTAssertEqual(subject.body?.email, "example@email.com")
        XCTAssertEqual(subject.body?.emailVerificationToken, "email-verification-token")
    }
}
