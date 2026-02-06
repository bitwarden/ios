import XCTest

@testable import AuthenticatorShared

// MARK: - OTPAuthModelTests

class OTPAuthModelTests: BitwardenTestCase {
    // MARK: Init Success

    /// `init` parses an account if there is no issuer
    func test_init_accountNoIssuer() {
        let key = "otpauth://totp/person@bitwarden.com?secret=JBSWY3DPEHPK3PXP"
        guard let subject = OTPAuthModel(otpAuthUri: key)
        else { XCTFail("Unable to parse auth model!"); return }
        XCTAssertEqual(subject.accountName, "person@bitwarden.com")
    }

    /// `init` parses all parameters when available
    func test_init_allParams() {
        // swiftlint:disable:next line_length
        let key = "otpauth://totp/Example:person@bitwarden.com?secret=JBSWY3DPEHPK3PXP&issuer=Example&algorithm=SHA256&digits=8&period=60"
        guard let subject = OTPAuthModel(otpAuthUri: key)
        else { XCTFail("Unable to parse auth model!"); return }
        XCTAssertEqual(subject.accountName, "person@bitwarden.com")
        XCTAssertEqual(subject.algorithm, .sha256)
        XCTAssertEqual(subject.digits, 8)
        XCTAssertEqual(subject.issuer, "Example")
        XCTAssertEqual(subject.period, 60)
        XCTAssertEqual(subject.secret, "JBSWY3DPEHPK3PXP")
    }

    /// `init` chooses the issuer parameter if it differs from the label
    func test_init_issuerParameter() {
        let key = "otpauth://totp/8bit:person@bitwarden.com?secret=JBSWY3DPEHPK3PXP&issuer=Bitwarden"
        guard let subject = OTPAuthModel(otpAuthUri: key)
        else { XCTFail("Unable to parse auth model!"); return }
        XCTAssertEqual(subject.issuer, "Bitwarden")
    }

    /// `init` parses the minimal necessary parameters and picks defaults
    func test_init_minimumParams() {
        let key = "otpauth://totp/?secret=JBSWY3DPEHPK3PXP"
        guard let subject = OTPAuthModel(otpAuthUri: key)
        else { XCTFail("Unable to parse auth model!"); return }
        XCTAssertNil(subject.accountName)
        XCTAssertEqual(subject.algorithm, .sha1)
        XCTAssertEqual(subject.digits, 6)
        XCTAssertNil(subject.issuer)
        XCTAssertEqual(subject.period, 30)
        XCTAssertEqual(subject.secret, "JBSWY3DPEHPK3PXP")
    }

    /// `init` handles a percent-encoded colon for issuer and account
    func test_init_percentEncoding() {
        let key = "otpauth://totp/Bitwarden%3Aperson@bitwarden.com?secret=JBSWY3DPEHPK3PXP&issuer=Bitwarden"
        guard let subject = OTPAuthModel(otpAuthUri: key)
        else { XCTFail("Unable to parse auth model!"); return }
        XCTAssertEqual(subject.accountName, "person@bitwarden.com")
        XCTAssertEqual(subject.issuer, "Bitwarden")
    }

    /// `init` handles special characters in issuer and account
    func test_init_specialCharacters() {
        // swiftlint:disable:next line_length
        let key = "otpauth://totp/Issuer%20Two%3A%20100%25%20the%20Sequel:person%3A2%40bitwarden%2Ecom?secret=JBSWY3DPEHPK3PXP&issuer=Issuer%20Two%3A%20100%25%20the%20Sequel"
        guard let subject = OTPAuthModel(otpAuthUri: key)
        else { XCTFail("Unable to parse auth model!"); return }
        XCTAssertEqual(subject.accountName, "person:2@bitwarden.com")
        XCTAssertEqual(subject.issuer, "Issuer Two: 100% the Sequel")
    }

    // MARK: Init Failure

    /// `init` returns nil if the secret is not valid base 32
    func test_init_failure_invalidSecret() {
        let key = "otpauth://totp/person@bitwarden.com?secret=invalid-secret"
        let subject = OTPAuthModel(otpAuthUri: key)
        XCTAssertNil(subject)
    }

    /// `init` returns nil if the scheme is missing or incorrect
    func test_init_failure_noScheme() {
        let subject = OTPAuthModel(otpAuthUri: "http://example?secret=JBSWY3DPEHPK3PXP")
        XCTAssertNil(subject)
    }

    /// `init` returns nil if the secret is missing
    func test_init_failure_noSecret() {
        let key = "otpauth://totp/Bitwarden:person@bitwarden.com?issuer=Bitwarden"
        let subject = OTPAuthModel(otpAuthUri: key)
        XCTAssertNil(subject)
    }

    /// `init` returns nil if the type is not "totp"
    func test_init_failure_notTotp() {
        let subject = OTPAuthModel(otpAuthUri: "otpauth://hotp/example?secret=JBSWY3DPEHPK3PXP")
        XCTAssertNil(subject)
    }

    // MARK: OTP Auth URI

    /// `otpAuthUri` handles having both an account and an issuer
    func test_otpAuthUri_BothIssuerAndAccount() {
        let subject = OTPAuthModel(
            accountName: "person@bitwarden.com",
            algorithm: .sha1,
            digits: 6,
            issuer: "Bitwarden",
            period: 30,
            secret: "JBSWY3DPEHPK3PXP",
        )
        // swiftlint:disable:next line_length
        XCTAssertEqual(subject.otpAuthUri, "otpauth://totp/Bitwarden:person%40bitwarden%2Ecom?secret=JBSWY3DPEHPK3PXP&issuer=Bitwarden&algorithm=SHA1&digits=6&period=30")
        XCTAssertEqual(OTPAuthModel(otpAuthUri: subject.otpAuthUri), subject)
    }

    /// `otpAuthUri` handles having neither an issuer nor an account name
    func test_otpAuthUri_noIssuerOrAccount() {
        let subject = OTPAuthModel(
            accountName: nil,
            algorithm: .sha1,
            digits: 6,
            issuer: nil,
            period: 30,
            secret: "JBSWY3DPEHPK3PXP",
        )
        XCTAssertEqual(subject.otpAuthUri, "otpauth://totp/?secret=JBSWY3DPEHPK3PXP&algorithm=SHA1&digits=6&period=30")
        XCTAssertEqual(OTPAuthModel(otpAuthUri: subject.otpAuthUri), subject)
    }

    /// `otpAuthUri` handles having an issuer but no account
    func test_otpAuthUri_noAccount() {
        let subject = OTPAuthModel(
            accountName: nil,
            algorithm: .sha1,
            digits: 6,
            issuer: "Bitwarden",
            period: 30,
            secret: "JBSWY3DPEHPK3PXP",
        )
        // swiftlint:disable:next line_length
        XCTAssertEqual(subject.otpAuthUri, "otpauth://totp/?secret=JBSWY3DPEHPK3PXP&issuer=Bitwarden&algorithm=SHA1&digits=6&period=30")
        XCTAssertEqual(OTPAuthModel(otpAuthUri: subject.otpAuthUri), subject)
    }

    /// `otpAuthUri` handles having an account but no issuer
    func test_otpAuthUri_noIssuer() {
        let subject = OTPAuthModel(
            accountName: "person@bitwarden.com",
            algorithm: .sha1,
            digits: 6,
            issuer: nil,
            period: 30,
            secret: "JBSWY3DPEHPK3PXP",
        )
        // swiftlint:disable:next line_length
        XCTAssertEqual(subject.otpAuthUri, "otpauth://totp/person%40bitwarden%2Ecom?secret=JBSWY3DPEHPK3PXP&algorithm=SHA1&digits=6&period=30")
        XCTAssertEqual(OTPAuthModel(otpAuthUri: subject.otpAuthUri), subject)
    }

    /// `otpAuthUri` handles special characters
    func test_otpAuthUri_specialCharacters() {
        let subject = OTPAuthModel(
            accountName: "person@bitwarden.com",
            algorithm: .sha1,
            digits: 6,
            issuer: "Issuer Two: 100% the Sequel",
            period: 30,
            secret: "JBSWY3DPEHPK3PXP",
        )
        // swiftlint:disable:next line_length
        XCTAssertEqual(subject.otpAuthUri, "otpauth://totp/Issuer%20Two%3A%20100%25%20the%20Sequel:person%40bitwarden%2Ecom?secret=JBSWY3DPEHPK3PXP&issuer=Issuer%20Two%3A%20100%25%20the%20Sequel&algorithm=SHA1&digits=6&period=30")
        XCTAssertEqual(OTPAuthModel(otpAuthUri: subject.otpAuthUri), subject)
    }
}
