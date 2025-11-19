import XCTest

import BitwardenResources
@testable import BitwardenShared

class TwoFactorAuthMethodTests: BitwardenTestCase {
    // MARK: Tests

    /// `details(_)` returns the correct values.
    func test_details() {
        XCTAssertEqual(TwoFactorAuthMethod.authenticatorApp.details(""), Localizations.enterVerificationCodeApp)
        XCTAssertEqual(TwoFactorAuthMethod.email.details("email"), Localizations.enterVerificationCodeEmail("email"))
        XCTAssertEqual(TwoFactorAuthMethod.recoveryCode.details(""), "")
    }

    /// `id` returns the expected value.
    func test_id() {
        XCTAssertEqual(TwoFactorAuthMethod.authenticatorApp.rawValue, TwoFactorAuthMethod.authenticatorApp.id)
    }

    /// `init(value:)` works as expected.
    func test_init() {
        XCTAssertEqual(TwoFactorAuthMethod(value: "0"), .authenticatorApp)
        XCTAssertEqual(TwoFactorAuthMethod(value: "1"), .email)
        XCTAssertNil(TwoFactorAuthMethod(value: ":)"))
    }

    /// `title` returns the correct values.
    func test_title() {
        XCTAssertEqual(TwoFactorAuthMethod.authenticatorApp.title, Localizations.authenticatorAppTitle)
        XCTAssertEqual(TwoFactorAuthMethod.email.title, Localizations.email)
        XCTAssertEqual(TwoFactorAuthMethod.recoveryCode.title, Localizations.recoveryCodeTitle)
        XCTAssertEqual(TwoFactorAuthMethod.remember.title, "")
    }

    /// `priority` returns the correct values.
    func test_priority() {
        XCTAssertEqual(TwoFactorAuthMethod.authenticatorApp.priority, 1)
        XCTAssertEqual(TwoFactorAuthMethod.email.priority, 0)
        XCTAssertEqual(TwoFactorAuthMethod.duo.priority, 2)
        XCTAssertEqual(TwoFactorAuthMethod.yubiKey.priority, 3)
        XCTAssertEqual(TwoFactorAuthMethod.u2F.priority, -1)
        XCTAssertEqual(TwoFactorAuthMethod.remember.priority, -1)
        XCTAssertEqual(TwoFactorAuthMethod.duoOrganization.priority, 10)
        XCTAssertEqual(TwoFactorAuthMethod.webAuthn.priority, 4)
        XCTAssertEqual(TwoFactorAuthMethod.recoveryCode.priority, -1)
    }
}
