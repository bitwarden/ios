import BitwardenKit
import XCTest

@testable import BitwardenShared

class EnvironmentURLDataTests: XCTestCase {
    // MARK: Tests

    /// `isEmpty` is true if none of the URLs are set.
    func test_isEmpty_empty() {
        XCTAssertTrue(EnvironmentURLData().isEmpty)
    }

    /// `isEmpty` is false if any of the URLs are set.
    func test_isEmpty_withURLs() {
        XCTAssertFalse(EnvironmentURLData(api: .example).isEmpty)
        XCTAssertFalse(EnvironmentURLData(base: .example).isEmpty)
        XCTAssertFalse(EnvironmentURLData(events: .example).isEmpty)
        XCTAssertFalse(EnvironmentURLData(icons: .example).isEmpty)
        XCTAssertFalse(EnvironmentURLData(identity: .example).isEmpty)
        XCTAssertFalse(EnvironmentURLData(notifications: .example).isEmpty)
        XCTAssertFalse(EnvironmentURLData(webVault: .example).isEmpty)
    }



    /// `webVaultHost` returns the host for the base URL if no web vault URL is set.
    func test_webVaultHost_baseURL() {
        let subject = EnvironmentURLData(base: URL(string: "https://vault.example.com"))
        XCTAssertEqual(subject.webVaultHost, "vault.example.com")
    }

    /// `webVaultHost` returns the host for the web vault URL.
    func test_webVaultHost_webVaultURL() {
        let subject = EnvironmentURLData(
            base: URL(string: "https://vault.bitwarden.com"),
            webVault: URL(string: "https://web.vault.bitwarden.com")
        )
        XCTAssertEqual(subject.webVaultHost, "web.vault.bitwarden.com")
    }

    /// `webVaultHost` returns `nil` if no web vault or base URL is set.
    func test_webVaultHost_nil() {
        let subject = EnvironmentURLData()
        XCTAssertNil(subject.webVaultHost)
    }
}
