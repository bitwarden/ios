import XCTest

@testable import BitwardenShared

class TOTPServiceErrorTests: BitwardenTestCase {
    // MARK: Tests

    /// `getter:errorUserInfo` gets the appropriate user info based on the error case.
    func test_errorUserInfo() {
        XCTAssertTrue(TOTPServiceError.unableToGenerateCode(nil).errorUserInfo.isEmpty)

        let errorWithDescription = TOTPServiceError.unableToGenerateCode("description")
        XCTAssertEqual(errorWithDescription.errorUserInfo["Description"] as? String, "description")
    }
}
