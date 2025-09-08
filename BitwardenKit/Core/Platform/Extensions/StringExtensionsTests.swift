import BitwardenKit
import Combine
import XCTest

class StringExtensionsTests: BitwardenTestCase {
    // MARK: Tests

    /// `fixURLIfNeeded()` returns the same string when it can be directly converted to `URL`.
    func test_fixURLIfNeeded_sameStringWhenCanConvertToURL() {
        let string = "https://bitwarden.com"
        XCTAssertEqual(string.fixURLIfNeeded(), "https://bitwarden.com")
    }

    /// `fixURLIfNeeded()` returns the same string prefixed with "http://" when it can't be
    /// directly converted to `URL` and it's an IP address.
    func test_fixURLIfNeeded_httpWhenIPAddress() {
        let string = "192.168.0.1:8080"
        XCTAssertEqual(string.fixURLIfNeeded(), "http://192.168.0.1:8080")
    }

    /// `fixURLIfNeeded()` returns the same string prefixed with "https://" when it can't be
    /// directly converted to `URL` and it's not an IP address.
    func test_fixURLIfNeeded_httpsWhenNotIPAddress() {
        let string = "ht tp://broken.com"
        XCTAssertEqual(string.fixURLIfNeeded(), "https://ht tp://broken.com")
    }
}
