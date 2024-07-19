import XCTest

@testable import BitwardenShared

// MARK: - TOTPCodeConfigTests

final class TOTPCodeConfigTests: BitwardenTestCase {
    // MARK: Tests

    /// Tests that a standard key string creates the model.
    func test_init_totpCodeConfig_standard() {
        let subject = TOTPKeyModel(authenticatorKey: .standardTotpKey)
        XCTAssertEqual(subject.key, .standardTotpKey)
    }

    /// Tests that a key string with spaces creates the model.
    func test_init_totpCodeConfig_spacesPresent() {
        let subject = TOTPKeyModel(authenticatorKey: .standardTotpKeyWithSpaces)
        XCTAssertEqual(subject.key, .standardTotpKeyWithSpaces)
    }

    /// Tests that an otp auth string creates the model.
    func test_init_totpCodeConfig_success_full() {
        let subject = TOTPKeyModel(authenticatorKey: .otpAuthUriKeyComplete)
        XCTAssertEqual(subject.key, .standardTotpKey)
    }

    /// Tests that an otp auth string creates the model.
    func test_init_totpCodeConfig_success_partial() {
        let subject = TOTPKeyModel(authenticatorKey: .otpAuthUriKeyPartial)
        XCTAssertEqual(subject.key, .standardTotpKey)
    }

    /// Tests that an otp auth string creates the model.
    func test_init_totpCodeConfig_success_sha512() {
        let subject = TOTPKeyModel(authenticatorKey: .otpAuthUriKeySHA512)
        XCTAssertEqual(subject.key, .standardTotpKey)
    }

    /// Tests that a steam string creates the model.
    func test_init_totpCodeConfig_success_steam() {
        let subject = TOTPKeyModel(authenticatorKey: .steamUriKey)
        XCTAssertEqual(subject.key, .standardTotpKey)
        XCTAssertEqual(subject.digits, 5)
        XCTAssertEqual(subject.algorithm, .sha1)
    }
}
