import XCTest

@testable import BitwardenShared

class URLTests: BitwardenTestCase {
    // MARK: Tests

    /// `sanitized` prepends a https scheme if the URL is missing a scheme.
    func test_sanitized_missingScheme() {
        XCTAssertEqual(
            URL(string: "bitwarden.com")?.sanitized,
            URL(string: "https://bitwarden.com")
        )
        XCTAssertEqual(
            URL(string: "example.com")?.sanitized,
            URL(string: "https://example.com")
        )
        XCTAssertEqual(
            URL(string: "vault.bitwarden.com/#/vault")?.sanitized,
            URL(string: "https://vault.bitwarden.com/#/vault")
        )
        XCTAssertEqual(
            URL(string: "google.com/search?q=bitwarden")?.sanitized,
            URL(string: "https://google.com/search?q=bitwarden")
        )
    }

    /// `sanitized` returns the URL unchanged if it's valid and contains a scheme.
    func test_sanitized_validURL() {
        XCTAssertEqual(
            URL(string: "https://bitwarden.com")?.sanitized,
            URL(string: "https://bitwarden.com")
        )
        XCTAssertEqual(
            URL(string: "http://bitwarden.com")?.sanitized,
            URL(string: "http://bitwarden.com")
        )
        XCTAssertEqual(
            URL(string: "https://vault.bitwarden.com/#/vault")?.sanitized,
            URL(string: "https://vault.bitwarden.com/#/vault")
        )
        XCTAssertEqual(
            URL(string: "https://google.com/search?q=bitwarden")?.sanitized,
            URL(string: "https://google.com/search?q=bitwarden")
        )
    }
}
