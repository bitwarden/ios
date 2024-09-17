import XCTest

@testable import BitwardenShared

class EnvironmentUrlDataTests: XCTestCase {
    // MARK: Tests

    /// `defaultUS` returns the properly configured `EnvironmentUrlData`
    /// with the deafult Urls for united states region.
    func test_defaultUS() {
        XCTAssertEqual(
            EnvironmentUrlData.defaultUS,
            EnvironmentUrlData(
                api: URL(string: "https://api.bitwarden.com")!,
                base: URL(string: "https://vault.bitwarden.com")!,
                events: URL(string: "https://events.bitwarden.com")!,
                icons: URL(string: "https://icons.bitwarden.net")!,
                identity: URL(string: "https://identity.bitwarden.com")!,
                notifications: URL(string: "https://notifications.bitwarden.com")!,
                webVault: URL(string: "https://vault.bitwarden.com")!
            )
        )
    }

    /// `defaultEU` returns the properly configured `EnvironmentUrlData`
    /// with the deafult Urls for europe region.
    func test_defaultEU() {
        XCTAssertEqual(
            EnvironmentUrlData.defaultEU,
            EnvironmentUrlData(
                api: URL(string: "https://api.bitwarden.eu")!,
                base: URL(string: "https://vault.bitwarden.eu")!,
                events: URL(string: "https://events.bitwarden.eu")!,
                icons: URL(string: "https://icons.bitwarden.eu")!,
                identity: URL(string: "https://identity.bitwarden.eu")!,
                notifications: URL(string: "https://notifications.bitwarden.eu")!,
                webVault: URL(string: "https://vault.bitwarden.eu")!
            )
        )
    }

    /// `importItemsURL` returns the import items url for the base url.
    func test_importItemsURL_baseURL() {
        let subject = EnvironmentUrlData(base: URL(string: "https://vault.example.com"))
        XCTAssertEqual(subject.importItemsURL?.absoluteString, "https://vault.example.com/#/tools/import")
    }

    /// `importItemsURL` returns the default import items base url.
    func test_importItemsURL_noURLs() {
        let subject = EnvironmentUrlData(base: nil, webVault: nil)
        XCTAssertNil(subject.importItemsURL?.absoluteString)
    }

    /// `importItemsURL` returns the import items url for the web vault url.
    func test_importItemsURL_webVaultURL() {
        let subject = EnvironmentUrlData(
            base: URL(string: "https://vault.example.com"),
            webVault: URL(string: "https://web.vault.example.com")
        )
        XCTAssertEqual(subject.importItemsURL?.absoluteString, "https://web.vault.example.com/#/tools/import")
    }

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

    /// `region` returns `.unitedStates` if base url is the same as the default for US.
    func test_region_unitedStates() {
        let subject = EnvironmentUrlData(base: URL(string: "https://vault.bitwarden.com")!)
        XCTAssertTrue(subject.region == .unitedStates)
    }

    /// `region` returns `.europe` if base url is the same as the default for EU.
    func test_region_europe() {
        let subject = EnvironmentUrlData(base: URL(string: "https://vault.bitwarden.eu")!)
        XCTAssertTrue(subject.region == .europe)
    }

    /// `region` returns `.selfHosted` if base url is neither the default for US nor for EU.
    func test_region_selfHost() {
        let subject = EnvironmentUrlData(base: URL(string: "https://example.com")!)
        XCTAssertTrue(subject.region == .selfHosted)
    }

    /// `sendShareURL` returns the send url for the united states region.
    func test_sendShareURL_unitedStates() {
        let subject = EnvironmentUrlData.defaultUS
        XCTAssertEqual(subject.sendShareURL?.absoluteString, "https://send.bitwarden.com/#")
    }

    /// `sendShareURL` returns the send url for the europe region.
    func test_sendShareURL_europe() {
        let subject = EnvironmentUrlData.defaultEU
        XCTAssertEqual(subject.sendShareURL?.absoluteString, "https://vault.bitwarden.eu/#/send")
    }

    /// `sendShareURL` returns the send url for the base url.
    func test_sendShareURL_baseURL() {
        let subject = EnvironmentUrlData(base: URL(string: "https://vault.example.com"))
        XCTAssertEqual(subject.sendShareURL?.absoluteString, "https://vault.example.com/#/send")
    }

    /// `sendShareURL` returns the default send base url.
    func test_sendShareURL_noURLs() {
        let subject = EnvironmentUrlData(base: nil, webVault: nil)
        XCTAssertNil(subject.sendShareURL?.absoluteString)
    }

    /// `sendShareURL` returns the send url for the web vault url.
    func test_sendShareURL_webVaultURL() {
        let subject = EnvironmentUrlData(
            base: URL(string: "https://vault.example.com"),
            webVault: URL(string: "https://web.vault.example.com")
        )
        XCTAssertEqual(subject.sendShareURL?.absoluteString, "https://web.vault.example.com/#/send")
    }

    /// `settingsURL` returns the settings url for the base url.
    func test_settingsURL_baseURL() {
        let subject = EnvironmentUrlData(base: URL(string: "https://vault.example.com"))
        XCTAssertEqual(subject.settingsURL?.absoluteString, "https://vault.example.com/#/settings")
    }

    /// `settingsURL` returns the default settings base url.
    func test_settingsURL_noURLs() {
        let subject = EnvironmentUrlData(base: nil, webVault: nil)
        XCTAssertNil(subject.settingsURL?.absoluteString)
    }

    /// `settingsURL` returns the settings url for the web vault url.
    func test_settingsURL_webVaultURL() {
        let subject = EnvironmentUrlData(
            base: URL(string: "https://vault.example.com"),
            webVault: URL(string: "https://web.vault.example.com")
        )
        XCTAssertEqual(subject.settingsURL?.absoluteString, "https://web.vault.example.com/#/settings")
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
