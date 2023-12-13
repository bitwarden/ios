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
                identityURL: URL(string: "https://example.com/identity")!
            )
        )
    }

    /// `init(environmentUrlData:)` sets the URLs based on the corresponding URL if there isn't a base URL.
    func test_init_environmentUrlData_custom() {
        let subject = EnvironmentUrls(
            environmentUrlData: EnvironmentUrlData(
                api: URL(string: "https://api.example.com")!,
                events: URL(string: "https://events.example.com")!,
                identity: URL(string: "https://identity.example.com")!
            )
        )
        XCTAssertEqual(
            subject,
            EnvironmentUrls(
                apiURL: URL(string: "https://api.example.com")!,
                baseURL: URL(string: "https://vault.bitwarden.com")!,
                eventsURL: URL(string: "https://events.example.com")!,
                identityURL: URL(string: "https://identity.example.com")!
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
                identityURL: URL(string: "https://identity.bitwarden.com")!
            )
        )
    }
}
