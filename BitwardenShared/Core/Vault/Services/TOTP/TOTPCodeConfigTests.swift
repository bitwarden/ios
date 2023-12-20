import XCTest

@testable import BitwardenShared

// MARK: - TOTPCodeConfigTests

final class TOTPCodeConfigTests: BitwardenTestCase {
    // MARK: Tests

    /// Tests that a malformed string does not create a model.
    func test_init_totpCodeConfig_failure_incompletePrefix() {
        let subject = TOTPCodeConfig(
            authenticatorKey: "totp/Example:eliot@livefront.com?secret=JBSWY3DPEHPK3PXP"
        )
        XCTAssertNil(subject)
    }

    /// Tests that a malformed string does not create a model.
    func test_init_totpCodeConfig_failure_noSecret() {
        let subject = TOTPCodeConfig(
            authenticatorKey: "otpauth://totp/Example:eliot@livefront.com?issuer=Example&algorithm=SHA256&digits=6&period=30" // swiftlint:disable:this line_length
        )
        XCTAssertNil(subject)
    }

    /// Tests that a base32 string creates the model.
    func test_init_totpCodeConfig_base32() {
        let subject = TOTPCodeConfig(
            authenticatorKey: .base32Key
        )
        XCTAssertNotNil(subject)
        XCTAssertEqual(subject?.base32Key, .base32Key)
    }

    /// Tests that an otp auth string creates the model.
    func test_init_totpCodeConfig_success_full() {
        let subject = TOTPCodeConfig(
            authenticatorKey: .otpAuthUriKeyComplete
        )
        XCTAssertNotNil(subject)
        XCTAssertEqual(
            subject?.base32Key,
            .base32Key.lowercased()
        )
    }

    /// Tests that an otp auth string creates the model.
    func test_init_totpCodeConfig_success_partial() {
        let subject = TOTPCodeConfig(
            authenticatorKey: .otpAuthUriKeyPartial
        )
        XCTAssertNotNil(subject)
        XCTAssertEqual(
            subject?.base32Key,
            .base32Key.lowercased()
        )
    }

    /// Tests that an otp auth string creates the model.
    func test_init_totpCodeConfig_success_sha512() {
        let subject = TOTPCodeConfig(
            authenticatorKey: .otpAuthUriKeySHA512
        )
        XCTAssertNotNil(subject)
        XCTAssertEqual(
            subject?.base32Key,
            .base32Key.lowercased()
        )
    }

    /// Tests that a steam string creates the model.
    func test_init_totpCodeConfig_success_steam() {
        let subject = TOTPCodeConfig(authenticatorKey: .steamUriKey)
        XCTAssertNotNil(subject)
        XCTAssertEqual(subject?.base32Key, .base32Key)
        XCTAssertEqual(subject?.digits, 5)
        XCTAssertEqual(subject?.algorithm, .sha1)
    }
}
