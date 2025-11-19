// swiftlint:disable:this file_name

import BitwardenSdk
import XCTest

@testable import BitwardenShared

class BitwardenErrorTests: BitwardenTestCase {
    // MARK: Tests

    /// `getter:errorUserInfo` gets the appropriate user info based on the message
    /// of the internal `BitwardenSdk.BitwardenError`.
    func test_errorUserInfo() {
        let expectedMessage = "Crypto(BitwardenSdk.CryptoError.Fingerprint(message: \"internal error\"))"
        let error = BitwardenSdk.BitwardenError.Crypto(CryptoError.Fingerprint(message: "internal error"))
        let nsError = error as NSError
        let userInfo = nsError.userInfo
        XCTAssertEqual(userInfo["SpecificError"] as? String, expectedMessage)
    }
}
