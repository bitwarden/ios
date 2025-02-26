import XCTest

@testable import BitwardenShared

class TOTPServiceErrorTests: BitwardenTestCase {
    // MARK: Tests

    /// `getter:errorUserInfo` gets the appropriate user info based on the error case.
    func test_errorUserInfo() {
        let invalidKeyFormatError = TOTPServiceError.invalidKeyFormat
        XCTAssertTrue(invalidKeyFormatError.errorUserInfo.isEmpty)

        let unableToGenerateCodeError = TOTPServiceError.unableToGenerateCode("description")
        XCTAssertEqual(unableToGenerateCodeError.errorUserInfo["Description"] as? String, "description")

        let unableToGenerateCodeErrorNoDescription = TOTPServiceError.unableToGenerateCode(nil)
        XCTAssertTrue(unableToGenerateCodeErrorNoDescription.errorUserInfo.isEmpty)
    }
}
