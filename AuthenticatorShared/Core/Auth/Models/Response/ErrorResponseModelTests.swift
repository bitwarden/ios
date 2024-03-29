import XCTest

@testable import AuthenticatorShared

// MARK: - ErrorResponseModelTests

class ErrorResponseModelTests: AuthenticatorTestCase {
    /// Tests that `singleMessage()` returns the validation error's message.
    func testSingleMessage() throws {
        let json = APITestData.createAccountAccountAlreadyExists.data
        let decoder = JSONDecoder()
        let subject = try decoder.decode(ErrorResponseModel.self, from: json)
        XCTAssertEqual(subject.singleMessage(), "Email 'j@a.com' is already taken.")
    }

    /// Tests that `singleMessage()` returns an error message when there are no validation errors.
    func testSingleMessageNilValidationErrors() throws {
        let json = APITestData.createAccountNilValidationErrors.data
        let decoder = JSONDecoder()
        let subject = try decoder.decode(ErrorResponseModel.self, from: json)
        XCTAssertEqual(subject.singleMessage(), "The model state is invalid.")
    }
}
