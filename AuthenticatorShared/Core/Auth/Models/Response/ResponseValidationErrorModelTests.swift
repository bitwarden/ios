import XCTest

@testable import AuthenticatorShared

// MARK: - ResponseValidationErrorModelTests

class ResponseValidationErrorModelTests: AuthenticatorTestCase {
    // MARK: - Tests

    /// Tests that a response is initialized correctly.
    func testInit() {
        let subject = ResponseValidationErrorModel(
            error: "invalid_input",
            errorDescription: "invalid_username",
            errorModel: ErrorModel(message: "error message", object: "error")
        )
        XCTAssertEqual(subject.errorModel.message, "error message")
    }

    /// Tests the successful decoding of a JSON response.
    func test_decode_success() throws {
        let json = APITestData.responseValidationError.data
        let subject = try ResponseValidationErrorModel.decoder.decode(ResponseValidationErrorModel.self, from: json)
        XCTAssertEqual(subject.errorModel.message, "Username or password is incorrect. Try again.")
    }
}
