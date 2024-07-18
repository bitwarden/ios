import XCTest

@testable import BitwardenShared

// MARK: - TOTPCodeConfigTests

final class TOTPCodeConfigTests: BitwardenTestCase {
    // MARK: Tests

    /// Tests that a malformed string does not create a model.
    func test_init_totpCodeConfig_failure_incompletePrefix() {
        let subject = TOTPKeyModel(
            authenticatorKey: "totp/Example:user@bitwarden.com?secret=JBSWY3DPEHPK3PXP"
        )
        XCTAssertNil(subject)
    }

    /// Tests that a malformed string does not create a model.
    func test_init_totpCodeConfig_failure_noSecret() {
        let subject = TOTPKeyModel(
            authenticatorKey: "otpauth://totp/Example:user@bitwarden.com?issuer=Example&algorithm=SHA256&digits=6&period=30" // swiftlint:disable:this line_length
        )
        XCTAssertNil(subject)
    }

    /// Tests that a base32 string creates the model.
    func test_init_totpCodeConfig_base32() {
        let subject = TOTPKeyModel(
            authenticatorKey: .base32Key
        )
        XCTAssertNotNil(subject)
        XCTAssertEqual(subject?.base32Key, .base32Key)
    }

    /// Tests that a base32 string creates the model.
    func test_init_totpCodeConfig_spacesPresent() {
        let subject = TOTPKeyModel(authenticatorKey: "BIT WAR DEN")
        XCTAssertNotNil(subject)
        XCTAssertEqual(subject?.base32Key, "BITWARDEN")
    }

    /// Tests that an otp auth string creates the model.
    func test_init_totpCodeConfig_success_full() {
        let subject = TOTPKeyModel(
            authenticatorKey: .otpAuthUriKeyComplete
        )
        XCTAssertNotNil(subject)
        XCTAssertEqual(
            subject?.base32Key,
            .base32Key
        )
    }

    /// Tests that an otp auth string creates the model.
    func test_init_totpCodeConfig_success_partial() {
        let subject = TOTPKeyModel(
            authenticatorKey: .otpAuthUriKeyPartial
        )
        XCTAssertNotNil(subject)
        XCTAssertEqual(
            subject?.base32Key,
            .base32Key
        )
    }

    /// Tests that an otp auth string creates the model.
    func test_init_totpCodeConfig_success_sha512() {
        let subject = TOTPKeyModel(
            authenticatorKey: .otpAuthUriKeySHA512
        )
        XCTAssertNotNil(subject)
        XCTAssertEqual(
            subject?.base32Key,
            .base32Key
        )
    }

    /// Tests that a steam string creates the model.
    func test_init_totpCodeConfig_success_steam() {
        let subject = TOTPKeyModel(authenticatorKey: .steamUriKey)
        XCTAssertNotNil(subject)
        XCTAssertEqual(subject?.base32Key, .base32Key)
        XCTAssertEqual(subject?.digits, 5)
        XCTAssertEqual(subject?.algorithm, .sha1)
    }
}
