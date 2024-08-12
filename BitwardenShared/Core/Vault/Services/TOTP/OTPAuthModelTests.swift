import XCTest

@testable import BitwardenShared

// MARK: - OTPAuthModelTests

class OTPAuthModelTests: BitwardenTestCase {
    // MARK: Tests

    /// Tests that a malformed string does not create a model.
    func test_init_otpAuthKey_failure_base32() {
        let subject = OTPAuthModel(otpAuthKey: .standardTotpKey)
        XCTAssertNil(subject)
    }

    /// Tests that a malformed string does not create a model.
    func test_init_otpAuthKey_failure_incompletePrefix() {
        let subject = OTPAuthModel(otpAuthKey: "totp/Example:user@bitwarden.com?secret=JBSWY3DPEHPK3PXP")
        XCTAssertNil(subject)
    }

    /// Tests that a malformed string does not create a model.
    func test_init_otpAuthKey_failure_noSecret() {
        let subject = OTPAuthModel(
            otpAuthKey: "otpauth://totp/Example:user@bitwarden.com?issuer=Example&algorithm=SHA256&digits=6&period=30"
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
        XCTAssertEqual(
            subject,
            OTPAuthModel(
                accountName: "user@bitwarden.com",
                algorithm: .sha256,
                digits: 6,
                issuer: "Example",
                key: "JBSWY3DPEHPK3PXP",
                period: 30,
                uri: .otpAuthUriKeyComplete
            )
        )
    }

    /// Test that a key with a issuer query parameter instead of in the label creates the model.
    func test_init_otpAuthKey_success_issuerQueryParam() {
        let key = "otpauth://totp/user@bitwarden.com?secret=JBSWY3DPEHPK3PXP&issuer=Bitwarden"
        let subject = OTPAuthModel(otpAuthKey: key)
        XCTAssertEqual(
            subject,
            OTPAuthModel(
                accountName: "user@bitwarden.com",
                algorithm: .sha1,
                digits: 6,
                issuer: "Bitwarden",
                key: "JBSWY3DPEHPK3PXP",
                period: 30,
                uri: key
            )
        )
    }

    /// Tests that a minimally formatted OTP Auth string creates the model.
    func test_init_otpAuthKey_success_minimum() {
        let subject = OTPAuthModel(otpAuthKey: .otpAuthUriKeyMinimum)
        XCTAssertEqual(
            subject,
            OTPAuthModel(
                accountName: nil,
                algorithm: .sha1,
                digits: 6,
                issuer: nil,
                key: "JBSWY3DPEHPK3PXP",
                period: 30,
                uri: .otpAuthUriKeyMinimum
            )
        )
    }

    /// Tests that an OTP Auth string with a non-base32 key creates a model.
    func test_init_otpAuthKey_success_nonbase32() {
        let subject = OTPAuthModel(otpAuthKey: .otpAuthUriKeyNonBase32)
        XCTAssertEqual(
            subject,
            OTPAuthModel(
                accountName: nil,
                algorithm: .sha1,
                digits: 6,
                issuer: nil,
                key: "1234567890",
                period: 30,
                uri: .otpAuthUriKeyNonBase32
            )
        )
    }

    /// Tests that a partially formatted OTP Auth string creates the model.
    func test_init_otpAuthKey_success_partial() {
        let subject = OTPAuthModel(otpAuthKey: .otpAuthUriKeyPartial)
        XCTAssertEqual(
            subject,
            OTPAuthModel(
                accountName: "user@bitwarden.com",
                algorithm: .sha1,
                digits: 6,
                issuer: "Example",
                key: "JBSWY3DPEHPK3PXP",
                period: 30,
                uri: .otpAuthUriKeyPartial
            )
        )
    }

    /// Test that a key with a percent encoded issuer creates the model.
    func test_init_otpAuthKey_success_percentEncodedIssuer() {
        let key = "otpauth://totp/ACME%20Co:user@bitwarden.com?secret=JBSWY3DPEHPK3PXP&issuer=ACME%20Co"
        let subject = OTPAuthModel(otpAuthKey: key)
        XCTAssertEqual(
            subject,
            OTPAuthModel(
                accountName: "user@bitwarden.com",
                algorithm: .sha1,
                digits: 6,
                issuer: "ACME Co",
                key: "JBSWY3DPEHPK3PXP",
                period: 30,
                uri: key
            )
        )
    }

    /// Test that a key with a percent encoded label separator creates the model.
    func test_init_otpAuthKey_success_percentEncodedLabelSeparator() {
        let key = "otpauth://totp/Bitwarden%3Auser@bitwarden.com?secret=JBSWY3DPEHPK3PXP&issuer=Bitwarden"
        let subject = OTPAuthModel(otpAuthKey: key)
        XCTAssertEqual(
            subject,
            OTPAuthModel(
                accountName: "user@bitwarden.com",
                algorithm: .sha1,
                digits: 6,
                issuer: "Bitwarden",
                key: "JBSWY3DPEHPK3PXP",
                period: 30,
                uri: key
            )
        )
    }
}
