import Networking
import XCTest

@testable import BitwardenShared

class DeleteAccountRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DeleteAccountRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DeleteAccountRequest()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// Validate that the method is correct.
    func test_method() {
        XCTAssertEqual(subject.method, .delete)
    }

    /// Validate that the path is correct.
    func test_path() {
        XCTAssertEqual(subject.path, "/accounts")
    }

    /// `validate(_:)` with a `399` status code does not throw an error.
    func test_validate_with399() throws {
        let response = HTTPResponse.failure(
            statusCode: 399,
            body: APITestData.deleteAccountRequestFailure.data
        )
        XCTAssertNoThrow(try subject.validate(response))
    }

    /// `validate(_:)` with a `400` status code throws a `.validate` error.
    func test_validate_with400() throws {
        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.deleteAccountRequestFailure.data
        )

        let errorResponse = try XCTUnwrap(ErrorResponseModel(response: response))

        XCTAssertThrowsError(try subject.validate(response)) { error in
            XCTAssertEqual(error as? DeleteAccountRequestError, .serverError(errorResponse))
        }
    }

    /// `validate(_:)` with a `499` status code throws a `.validate` error.
    func test_validate_with499() throws {
        let response = HTTPResponse.failure(
            statusCode: 499,
            body: APITestData.deleteAccountRequestFailure.data
        )

        let errorResponse = try XCTUnwrap(ErrorResponseModel(response: response))

        XCTAssertThrowsError(try subject.validate(response)) { error in
            XCTAssertEqual(error as? DeleteAccountRequestError, .serverError(errorResponse))
        }
    }

    /// `validate(_:)` with a `500` status code does not throw an error.
    func test_validate_with500() throws {
        let response = HTTPResponse.failure(
            statusCode: 500,
            body: APITestData.deleteAccountRequestFailure.data
        )
        XCTAssertNoThrow(try subject.validate(response))
    }
}
