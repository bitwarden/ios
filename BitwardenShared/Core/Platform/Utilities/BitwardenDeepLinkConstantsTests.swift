import XCTest

@testable import BitwardenShared

class BitwardenDeepLinkConstantsTests: BitwardenTestCase {
    // MARK: Tests

    /// `accountSecurity` has the expected deep link value.
    func test_accountSecurity_value() {
        XCTAssertEqual(BitwardenDeepLinkConstants.accountSecurity, "bitwarden://settings/account_security")
    }

    /// `authenticatorNewItem` has the expected deep link value.
    func test_authenticatorNewItem_value() {
        XCTAssertEqual(BitwardenDeepLinkConstants.authenticatorNewItem, "bitwarden://authenticator/newItem")
    }

    /// `ssoCookieVendor` has the expected deep link base URL.
    func test_ssoCookieVendor_value() {
        XCTAssertEqual(BitwardenDeepLinkConstants.ssoCookieVendor, "bitwarden://sso-cookie-vendor")
    }
}
