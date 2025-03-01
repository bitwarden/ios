import XCTest

@testable import AuthenticatorShared

class EmptyInputValidatorTests: AuthenticatorTestCase {
    // MARK: Tests

    /// `validate(input:)` doesn't throw an error if the input is valid.
    func test_validate_success() {
        let subject = EmptyInputValidator(fieldName: "Email")

        XCTAssertNoThrow(try subject.validate(input: "a"))
        XCTAssertNoThrow(try subject.validate(input: "user@bitwarden.com"))
    }

    /// `validate(input:)` throw an `InputValidationError` if the input is invalid.
    func test_validate_error() {
        let subject = EmptyInputValidator(fieldName: "Email")

        func assertThrowsInputValidationError(
            input: String?,
            file: StaticString = #filePath,
            line: UInt = #line
        ) {
            XCTAssertThrowsError(try subject.validate(input: input)) { error in
                XCTAssertTrue(error is InputValidationError)
                XCTAssertEqual(
                    error as? InputValidationError,
                    InputValidationError(message: "The Email field is required.")
                )
            }
        }

        assertThrowsInputValidationError(input: nil)
        assertThrowsInputValidationError(input: " ")
        assertThrowsInputValidationError(input: "   ")
        assertThrowsInputValidationError(input: "\n")
    }
}
