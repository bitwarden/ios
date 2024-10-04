// swiftlint:disable:this file_name

import XCTest

@testable import BitwardenShared

class KeychainServiceErrorTests: BitwardenTestCase {
    // MARK: Tests

    /// `getter:errorUserInfo` gets the appropriate user info based on the error case.
    func test_errorUserInfo() {
        let errorAccessControlFailed = KeychainServiceError.accessControlFailed(nil)
        XCTAssertTrue(errorAccessControlFailed.errorUserInfo.isEmpty)

        let errorKeyNotFound = KeychainServiceError.keyNotFound(KeychainItem.refreshToken(userId: "1"))
        XCTAssertEqual(errorKeyNotFound.errorUserInfo["Keychain Item"] as? String, "refreshToken_1")

        let errorOSStatusError = KeychainServiceError.osStatusError(3)
        XCTAssertEqual(errorOSStatusError.errorUserInfo["OS Status"] as? Int32, 3)
    }
}
