import XCTest

@testable import BitwardenShared

class EnvironmentUrlsTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(environmentUrlData:)` sets the URLs from the base URL if one is set.
    func test_init_environmentUrlData_baseUrl() {
        let subject = EnvironmentUrls(
            environmentUrlData: EnvironmentUrlData(base: URL(string: "https://example.com")!)
        )
        XCTAssertEqual(
            subject,
            EnvironmentUrls(
                apiURL: URL(string: "https://example.com/api")!,
                baseURL: URL(string: "https://example.com")!,
                eventsURL: URL(string: "https://example.com/events")!,
                iconsURL: URL(string: "https://example.com/icons")!,
                identityURL: URL(string: "https://example.com/identity")!,
                sendShareURL: URL(string: "https://example.com/#/send")!,
                webVaultURL: URL(string: "https://example.com")!
            )
        )
    }

    /// `init(environmentUrlData:)` sets the URLs based on the corresponding URL if there isn't a base URL.
    func test_init_environmentUrlData_custom() {
        let subject = EnvironmentUrls(
            environmentUrlData: EnvironmentUrlData(
                api: URL(string: "https://api.example.com")!,
                events: URL(string: "https://events.example.com")!,
                icons: URL(string: "https://icons.example.com")!,
                identity: URL(string: "https://identity.example.com")!,
                webVault: URL(string: "https://example.com")!
            )
        )
        XCTAssertEqual(
            subject,
            EnvironmentUrls(
                apiURL: URL(string: "https://api.example.com")!,
                baseURL: URL(string: "https://vault.bitwarden.com")!,
                eventsURL: URL(string: "https://events.example.com")!,
                iconsURL: URL(string: "https://icons.example.com")!,
                identityURL: URL(string: "https://identity.example.com")!,
                sendShareURL: URL(string: "https://example.com/#/send")!,
                webVaultURL: URL(string: "https://example.com")!
            )
        )
    }

    /// `init(environmentUrlData:)` sets the URLs to default values if the URLs are empty.
    func test_init_environmentUrlData_empty() {
        let subject = EnvironmentUrls(environmentUrlData: EnvironmentUrlData())
        XCTAssertEqual(
            subject,
            EnvironmentUrls(
                apiURL: URL(string: "https://api.bitwarden.com")!,
                baseURL: URL(string: "https://vault.bitwarden.com")!,
                eventsURL: URL(string: "https://events.bitwarden.com")!,
                iconsURL: URL(string: "https://icons.bitwarden.net")!,
                identityURL: URL(string: "https://identity.bitwarden.com")!,
                sendShareURL: URL(string: "https://send.bitwarden.com/#")!,
                webVaultURL: URL(string: "https://vault.bitwarden.com")!
            )
        )
    }
}
