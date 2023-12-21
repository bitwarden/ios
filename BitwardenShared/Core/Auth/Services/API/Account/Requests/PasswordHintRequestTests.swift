import Networking
import XCTest

@testable import BitwardenShared

// MARK: - PasswordHintRequestTests

class PasswordHintRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: PasswordHintRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = PasswordHintRequest(body: PasswordHintRequestModel(email: "email@example.com"))
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
        XCTAssertEqual(subject.path, "/accounts/password-hint")
    }

    /// `validate(_:)` with a `399` status code does not throw an error.
    func test_validate_with399() throws {
        let response = HTTPResponse.failure(
            statusCode: 399,
            body: APITestData.passwordHintFailure.data
        )
        XCTAssertNoThrow(try subject.validate(response))
    }

    /// `validate(_:)` with a `400` status code throws a `.serverError` error.
    func test_validate_with400() throws {
        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.passwordHintFailure.data
        )

        let errorResponse = try XCTUnwrap(ErrorResponseModel(response: response))

        XCTAssertThrowsError(try subject.validate(response)) { error in
            XCTAssertEqual(error as? PasswordHintRequestError, .serverError(errorResponse))
        }
    }

    /// `validate(_:)` with a `499` status code throws a `.serverError` error.
    func test_validate_with499() throws {
        let response = HTTPResponse.failure(
            statusCode: 499,
            body: APITestData.passwordHintFailure.data
        )

        let errorResponse = try XCTUnwrap(ErrorResponseModel(response: response))

        XCTAssertThrowsError(try subject.validate(response)) { error in
            XCTAssertEqual(error as? PasswordHintRequestError, .serverError(errorResponse))
        }
    }

    /// `validate(_:)` with a `500` status code does not throw an error.
    func test_validate_with500() throws {
        let response = HTTPResponse.failure(
            statusCode: 500,
            body: APITestData.passwordHintFailure.data
        )
        XCTAssertNoThrow(try subject.validate(response))
    }
}
