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

    /// `validate(_:)` with a `400` status code throws a `.validate` error.
    func test_validate_with400() throws {
        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.deleteAccountRequestFailure.data
        )

        guard let errorResponse = try? ErrorResponseModel(response: response) else { return }

        XCTAssertThrowsError(try subject.validate(response)) { error in
            XCTAssertEqual(error as? DeleteAccountRequestError, .serverError(errorResponse))
        }
    }
}
