import XCTest

@testable import BitwardenShared

class EnvironmentUrlDataTests: XCTestCase {
    // MARK: Tests

    /// `isEmpty` is true if none of the URLs are set.
    func test_isEmpty_empty() {
        XCTAssertTrue(EnvironmentUrlData().isEmpty)
    }

    /// `isEmpty` is false if any of the URLs are set.
    func test_isEmpty_withURLs() {
        XCTAssertFalse(EnvironmentUrlData(api: .example).isEmpty)
        XCTAssertFalse(EnvironmentUrlData(base: .example).isEmpty)
        XCTAssertFalse(EnvironmentUrlData(events: .example).isEmpty)
        XCTAssertFalse(EnvironmentUrlData(icons: .example).isEmpty)
        XCTAssertFalse(EnvironmentUrlData(identity: .example).isEmpty)
        XCTAssertFalse(EnvironmentUrlData(notifications: .example).isEmpty)
        XCTAssertFalse(EnvironmentUrlData(webVault: .example).isEmpty)
    }

    /// `webVaultHost` returns the host for the base URL if no web vault URL is set.
    func test_webVaultHost_baseURL() {
        let subject = EnvironmentUrlData(base: URL(string: "https://vault.example.com"))
        XCTAssertEqual(subject.webVaultHost, "vault.example.com")
    }

    /// `webVaultHost` returns the host for the web vault URL.
    func test_webVaultHost_webVaultURL() {
        let subject = EnvironmentUrlData(
            base: URL(string: "https://vault.bitwarden.com"),
            webVault: URL(string: "https://web.vault.bitwarden.com")
        )
        XCTAssertEqual(subject.webVaultHost, "web.vault.bitwarden.com")
    }

    /// `webVaultHost` returns `nil` if no web vault or base URL is set.
    func test_webVaultHost_nil() {
        let subject = EnvironmentUrlData()
        XCTAssertNil(subject.webVaultHost)
    }
}
