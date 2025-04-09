import XCTest

@testable import BitwardenKit

class EnvironmentURLDataTests: XCTestCase {
    // MARK: Tests
    /// `changeEmailURL` returns the change email URL for the base URL.
    func test_changeEmailURL_baseURL() {
        let subject = EnvironmentURLData(base: URL(string: "https://vault.example.com"))
        XCTAssertEqual(subject.changeEmailURL?.absoluteString, "https://vault.example.com/#/settings/account")
    }

    /// `changeEmailURL` returns the default change email base URL.
    func test_changeEmailURL_noURLs() {
        let subject = EnvironmentURLData(base: nil, webVault: nil)
        XCTAssertNil(subject.changeEmailURL?.absoluteString)
    }

    /// `changeEmailURL` returns the change email URL for the web vault URL.
    func test_changeEmailURL_webVaultURL() {
        let subject = EnvironmentURLData(
            base: URL(string: "https://vault.example.com"),
            webVault: URL(string: "https://web.vault.example.com")
        )
        XCTAssertEqual(subject.changeEmailURL?.absoluteString, "https://web.vault.example.com/#/settings/account")
    }

    /// `importItemsURL` returns the import items URL for the base URL.
    func test_importItemsURL_baseURL() {
        let subject = EnvironmentURLData(base: URL(string: "https://vault.example.com"))
        XCTAssertEqual(subject.importItemsURL?.absoluteString, "https://vault.example.com/#/tools/import")
    }

    /// `importItemsURL` returns the default import items base URL.
    func test_importItemsURL_noURLs() {
        let subject = EnvironmentURLData(base: nil, webVault: nil)
        XCTAssertNil(subject.importItemsURL?.absoluteString)
    }

    /// `importItemsURL` returns the import items URL for the web vault URL.
    func test_importItemsURL_webVaultURL() {
        let subject = EnvironmentURLData(
            base: URL(string: "https://vault.example.com"),
            webVault: URL(string: "https://web.vault.example.com")
        )
        XCTAssertEqual(subject.importItemsURL?.absoluteString, "https://web.vault.example.com/#/tools/import")
    }

    /// `recoveryCodeURL` returns the recovery code URL for the base URL.
    func test_recoveryCodeURL_baseURL() {
        let subject = EnvironmentURLData(base: URL(string: "https://vault.example.com"))
        XCTAssertEqual(subject.recoveryCodeURL?.absoluteString, "https://vault.example.com/#/recover-2fa")
    }

    /// `recoveryCodeURL` returns the default settings base URL.
    func test_recoveryCodeURL_noURLs() {
        let subject = EnvironmentURLData(base: nil, webVault: nil)
        XCTAssertNil(subject.recoveryCodeURL?.absoluteString)
    }

    /// `recoveryCodeURL` returns the settings URL for the web vault URL.
    func test_recoveryCodeURL_webVaultURL() {
        let subject = EnvironmentURLData(
            base: URL(string: "https://vault.example.com"),
            webVault: URL(string: "https://web.vault.example.com")
        )
        XCTAssertEqual(subject.recoveryCodeURL?.absoluteString, "https://web.vault.example.com/#/recover-2fa")
    }

    /// `sendShareURL` returns the send URL for the united states region.
    func test_sendShareURL_unitedStates() {
        let subject = EnvironmentURLData.defaultUS
        XCTAssertEqual(subject.sendShareURL?.absoluteString, "https://send.bitwarden.com/#")
    }

    /// `sendShareURL` returns the send URL for the europe region.
    func test_sendShareURL_europe() {
        let subject = EnvironmentURLData.defaultEU
        XCTAssertEqual(subject.sendShareURL?.absoluteString, "https://vault.bitwarden.eu/#/send")
    }

    /// `sendShareURL` returns the send URL for the base URL.
    func test_sendShareURL_baseURL() {
        let subject = EnvironmentURLData(base: URL(string: "https://vault.example.com"))
        XCTAssertEqual(subject.sendShareURL?.absoluteString, "https://vault.example.com/#/send")
    }

    /// `sendShareURL` returns the default send base URL.
    func test_sendShareURL_noURLs() {
        let subject = EnvironmentURLData(base: nil, webVault: nil)
        XCTAssertNil(subject.sendShareURL?.absoluteString)
    }

    /// `sendShareURL` returns the send URL for the web vault URL.
    func test_sendShareURL_webVaultURL() {
        let subject = EnvironmentURLData(
            base: URL(string: "https://vault.example.com"),
            webVault: URL(string: "https://web.vault.example.com")
        )
        XCTAssertEqual(subject.sendShareURL?.absoluteString, "https://web.vault.example.com/#/send")
    }

    /// `settingsURL` returns the settings URL for the base URL.
    func test_settingsURL_baseURL() {
        let subject = EnvironmentURLData(base: URL(string: "https://vault.example.com"))
        XCTAssertEqual(subject.settingsURL?.absoluteString, "https://vault.example.com/#/settings")
    }

    /// `settingsURL` returns the default settings base URL.
    func test_settingsURL_noURLs() {
        let subject = EnvironmentURLData(base: nil, webVault: nil)
        XCTAssertNil(subject.settingsURL?.absoluteString)
    }

    /// `settingsURL` returns the settings URL for the web vault URL.
    func test_settingsURL_webVaultURL() {
        let subject = EnvironmentURLData(
            base: URL(string: "https://vault.example.com"),
            webVault: URL(string: "https://web.vault.example.com")
        )
        XCTAssertEqual(subject.settingsURL?.absoluteString, "https://web.vault.example.com/#/settings")
    }

    /// `setUpTwoFactorURL` returns the change email URL for the base URL.
    func test_setUpTwoFactorURL_baseURL() {
        let subject = EnvironmentURLData(base: URL(string: "https://vault.example.com"))
        XCTAssertEqual(
            subject.setUpTwoFactorURL?.absoluteString,
            "https://vault.example.com/#/settings/security/two-factor"
        )
    }

    /// `setUpTwoFactorURL` returns the default change email base URL.
    func test_setUpTwoFactorURL_noURLs() {
        let subject = EnvironmentURLData(base: nil, webVault: nil)
        XCTAssertNil(subject.setUpTwoFactorURL?.absoluteString)
    }

    /// `setUpTwoFactorURL` returns the change email URL for the web vault URL.
    func test_setUpTwoFactorURL_webVaultURL() {
        let subject = EnvironmentURLData(
            base: URL(string: "https://vault.example.com"),
            webVault: URL(string: "https://web.vault.example.com")
        )
        XCTAssertEqual(
            subject.setUpTwoFactorURL?.absoluteString,
            "https://web.vault.example.com/#/settings/security/two-factor"
        )
    }
}
