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
            webVault: URL(string: "https://web.vault.example.com"),
        )
        XCTAssertEqual(subject.changeEmailURL?.absoluteString, "https://web.vault.example.com/#/settings/account")
    }

    /// `defaultUS` returns the properly configured `EnvironmentURLData`
    /// with the default Urls for united states region.
    func test_defaultUS() {
        XCTAssertEqual(
            EnvironmentURLData.defaultUS,
            EnvironmentURLData(
                api: URL(string: "https://api.bitwarden.com")!,
                base: URL(string: "https://vault.bitwarden.com")!,
                events: URL(string: "https://events.bitwarden.com")!,
                icons: URL(string: "https://icons.bitwarden.net")!,
                identity: URL(string: "https://identity.bitwarden.com")!,
                notifications: URL(string: "https://notifications.bitwarden.com")!,
                webVault: URL(string: "https://vault.bitwarden.com")!,
            ),
        )
    }

    /// `defaultEU` returns the properly configured `EnvironmentURLData`
    /// with the default Urls for europe region.
    func test_defaultEU() {
        XCTAssertEqual(
            EnvironmentURLData.defaultEU,
            EnvironmentURLData(
                api: URL(string: "https://api.bitwarden.eu")!,
                base: URL(string: "https://vault.bitwarden.eu")!,
                events: URL(string: "https://events.bitwarden.eu")!,
                icons: URL(string: "https://icons.bitwarden.eu")!,
                identity: URL(string: "https://identity.bitwarden.eu")!,
                notifications: URL(string: "https://notifications.bitwarden.eu")!,
                webVault: URL(string: "https://vault.bitwarden.eu")!,
            ),
        )
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
            webVault: URL(string: "https://web.vault.example.com"),
        )
        XCTAssertEqual(subject.importItemsURL?.absoluteString, "https://web.vault.example.com/#/tools/import")
    }

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
            webVault: URL(string: "https://web.vault.example.com"),
        )
        XCTAssertEqual(subject.recoveryCodeURL?.absoluteString, "https://web.vault.example.com/#/recover-2fa")
    }

    /// `region` returns `.unitedStates` if base URL is the same as the default for US.
    func test_region_unitedStates() {
        let subject = EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com")!)
        XCTAssertTrue(subject.region == .unitedStates)
    }

    /// `region` returns `.europe` if base URL is the same as the default for EU.
    func test_region_europe() {
        let subject = EnvironmentURLData(base: URL(string: "https://vault.bitwarden.eu")!)
        XCTAssertTrue(subject.region == .europe)
    }

    /// `region` returns `.selfHosted` if base URL is neither the default for US nor for EU.
    func test_region_selfHost() {
        let subject = EnvironmentURLData(base: URL(string: "https://example.com")!)
        XCTAssertTrue(subject.region == .selfHosted)
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
            webVault: URL(string: "https://web.vault.example.com"),
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
            webVault: URL(string: "https://web.vault.example.com"),
        )
        XCTAssertEqual(subject.settingsURL?.absoluteString, "https://web.vault.example.com/#/settings")
    }

    /// `setUpTwoFactorURL` returns the change email URL for the base URL.
    func test_setUpTwoFactorURL_baseURL() {
        let subject = EnvironmentURLData(base: URL(string: "https://vault.example.com"))
        XCTAssertEqual(
            subject.setUpTwoFactorURL?.absoluteString,
            "https://vault.example.com/#/settings/security/two-factor",
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
            webVault: URL(string: "https://web.vault.example.com"),
        )
        XCTAssertEqual(
            subject.setUpTwoFactorURL?.absoluteString,
            "https://web.vault.example.com/#/settings/security/two-factor",
        )
    }

    /// `upgradeToPremiumURL` returns the upgrade to premium URL.
    func test_upgradeToPremiumURL() {
        let subject = EnvironmentURLData(
            base: URL(string: "https://vault.example.com"),
        )
        XCTAssertEqual(
            subject.upgradeToPremiumURL?.absoluteString,
            "https://vault.example.com/#/settings/subscription/premium?callToAction=upgradeToPremium",
        )
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
            webVault: URL(string: "https://web.vault.bitwarden.com"),
        )
        XCTAssertEqual(subject.webVaultHost, "web.vault.bitwarden.com")
    }

    /// `webVaultHost` returns `nil` if no web vault or base URL is set.
    func test_webVaultHost_nil() {
        let subject = EnvironmentURLData()
        XCTAssertNil(subject.webVaultHost)
    }
}
