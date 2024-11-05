// swiftlint:disable:this file_name

import BitwardenSdk
import XCTest

@testable import BitwardenShared

class BitwardenErrorTests: BitwardenTestCase {
    // MARK: Tests

    /// `getter:errorUserInfo` gets the appropriate user info based on the message of the error `E`
    func test_errorUserInfo() {
        let expectedMessage = "expectedMessage"
        let error = BitwardenSdk.BitwardenError.E(message: expectedMessage)
        let userInfo = error.errorUserInfo
        XCTAssertEqual(userInfo["Message"] as? String, expectedMessage)
    }
}
