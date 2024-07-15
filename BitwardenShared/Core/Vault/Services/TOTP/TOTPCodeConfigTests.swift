import XCTest

@testable import BitwardenShared

// MARK: - TOTPCodeConfigTests

final class TOTPCodeConfigTests: BitwardenTestCase {
    // MARK: Tests

    /// Tests that a base32 string creates the model.
    func test_init_totpCodeConfig_base32() {
        let subject = TOTPKeyModel(authenticatorKey: .base32Key)
        XCTAssertEqual(subject.base32Key, .base32Key)
    }

    /// Tests that an otp auth string creates the model.
    func test_init_totpCodeConfig_success_full() {
        let subject = TOTPKeyModel(authenticatorKey: .otpAuthUriKeyComplete)
        XCTAssertEqual(subject.base32Key, .base32Key)
    }

    /// Tests that an otp auth string creates the model.
    func test_init_totpCodeConfig_success_partial() {
        let subject = TOTPKeyModel(authenticatorKey: .otpAuthUriKeyPartial)
        XCTAssertEqual(subject.base32Key, .base32Key)
    }

    /// Tests that an otp auth string creates the model.
    func test_init_totpCodeConfig_success_sha512() {
        let subject = TOTPKeyModel(authenticatorKey: .otpAuthUriKeySHA512)
        XCTAssertEqual(subject.base32Key, .base32Key)
    }

    /// Tests that a steam string creates the model.
    func test_init_totpCodeConfig_success_steam() {
        let subject = TOTPKeyModel(authenticatorKey: .steamUriKey)
        XCTAssertEqual(subject.base32Key, .base32Key)
        XCTAssertEqual(subject.digits, 5)
        XCTAssertEqual(subject.algorithm, .sha1)
    }
}
