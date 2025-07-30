import TestHelpers
import XCTest

@testable import BitwardenKit

// MARK: - ErrorResponseModelTests

class ErrorResponseModelTests: BitwardenTestCase {
    /// Tests that `singleMessage()` returns the validation error's message.
    func test_singleMessage() throws {
        let json = APITestData.registerFinishAccountAlreadyExists.data
        let decoder = JSONDecoder()
        let subject = try decoder.decode(ErrorResponseModel.self, from: json)
        XCTAssertEqual(subject.singleMessage(), "Email 'j@a.com' is already taken.")
    }

    /// Tests that `singleMessage()` returns an error message when there are no validation errors.
    func test_singleMessage_nilValidationErrors() throws {
        let json = APITestData.createAccountNilValidationErrors.data
        let decoder = JSONDecoder()
        let subject = try decoder.decode(ErrorResponseModel.self, from: json)
        XCTAssertEqual(subject.singleMessage(), "The model state is invalid.")
    }
}
