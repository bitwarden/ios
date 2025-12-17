import BitwardenKit
import BitwardenKitMocks
import XCTest

class KeychainServiceErrorTests: BitwardenTestCase {
    // MARK: Tests

    /// `getter:errorUserInfo` gets the appropriate user info based on the error case.
    func test_errorUserInfo() {
        let errorAccessControlFailed = KeychainServiceError.accessControlFailed(nil)
        XCTAssertTrue(errorAccessControlFailed.errorUserInfo.isEmpty)

        let keyThatWasNotFound = MockKeychainStorageKeyPossessing()
        keyThatWasNotFound.unformattedKey = "refreshToken_1"
        let errorKeyNotFound = KeychainServiceError.keyNotFound(keyThatWasNotFound)
        XCTAssertEqual(errorKeyNotFound.errorUserInfo["Keychain Item"] as? String, "refreshToken_1")

        let errorOSStatusError = KeychainServiceError.osStatusError(3)
        XCTAssertEqual(errorOSStatusError.errorUserInfo["OS Status"] as? Int32, 3)
    }
}
