import XCTest

@testable import BitwardenShared

// MARK: - OTPAuthModelTests

class OTPAuthModelTests: BitwardenTestCase {
    // MARK: Tests

    /// Tests that a malformed string does not create a model.
    func test_init_otpAuthKey_failure_base32() {
        let subject = OTPAuthModel(otpAuthKey: .base32Key)
        XCTAssertNil(subject)
    }

    /// Tests that a malformed string does not create a model.
    func test_init_otpAuthKey_failure_incompletePrefix() {
        let subject = OTPAuthModel(otpAuthKey: "totp/Example:eliot@livefront.com?secret=JBSWY3DPEHPK3PXP")
        XCTAssertNil(subject)
    }

    /// Tests that a malformed string does not create a model.
    func test_init_otpAuthKey_failure_noSecret() {
        let subject = OTPAuthModel(
            otpAuthKey: "otpauth://totp/Example:eliot@livefront.com?issuer=Example&algorithm=SHA256&digits=6&period=30"
        )
        XCTAssertNil(subject)
    }

    /// Tests that a malformed string does not create a model.
    func test_init_otpAuthKey_failure_steam() {
        let subject = OTPAuthModel(otpAuthKey: .steamUriKey)
        XCTAssertNil(subject)
    }

    /// Tests that a fully formatted OTP Auth string creates the model.
    func test_init_otpAuthKey_success_full() {
        let subject = OTPAuthModel(otpAuthKey: .otpAuthUriKeyComplete)
        XCTAssertNotNil(subject)
    }

    /// Tests that a partially formatted OTP Auth string creates the model.
    func test_init_otpAuthKey_success_partial() {
        let subject = OTPAuthModel(otpAuthKey: .otpAuthUriKeyPartial)
        XCTAssertNotNil(subject)
        XCTAssertEqual(subject?.digits, 6)
        XCTAssertEqual(subject?.period, 30)
        XCTAssertEqual(subject?.algorithm, .sha1)
    }
}
