import XCTest

@testable import BitwardenShared

// MARK: - LoginTOTPStateTests

class LoginTOTPStateTests: BitwardenTestCase {
    func test_init_authKeyString_valid() {
        let subject = LoginTOTPState("valid")
        XCTAssertEqual(subject, .key(TOTPKeyModel(authenticatorKey: "valid")))
    }

    func test_init_authKeyString_nil() {
        let subject = LoginTOTPState(nil)
        XCTAssertEqual(subject, .none)
    }

    func test_init_authKeyString_empty() {
        let subject = LoginTOTPState("")
        XCTAssertEqual(subject, .none)
    }

    func test_init_authKeyString_internalWhitespace() {
        let subject = LoginTOTPState("space key")
        XCTAssertEqual(subject, .key(TOTPKeyModel(authenticatorKey: "space key")))
    }

    func test_init_authKeyString_justWhitespaces() {
        let subject = LoginTOTPState("     ")
        XCTAssertEqual(subject, .none)
    }
}
