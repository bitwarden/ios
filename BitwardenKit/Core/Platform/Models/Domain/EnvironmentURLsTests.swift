import XCTest

@testable import BitwardenKit

class EnvironmentURLsTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(environmentURLData:)` sets the URLs from the passed data when such data is the default US.
    func test_init_environmentURLData_defaultUS() {
        let subject = EnvironmentURLs(
            environmentURLData: EnvironmentURLData.defaultUS,
        )
        XCTAssertEqual(
            subject,
            EnvironmentURLs(
                apiURL: URL(string: "https://api.bitwarden.com")!,
                baseURL: URL(string: "https://vault.bitwarden.com")!,
                changeEmailURL: URL(string: "https://vault.bitwarden.com/#/settings/account")!,
                eventsURL: URL(string: "https://events.bitwarden.com")!,
                iconsURL: URL(string: "https://icons.bitwarden.net")!,
                identityURL: URL(string: "https://identity.bitwarden.com")!,
                importItemsURL: URL(string: "https://vault.bitwarden.com/#/tools/import")!,
                recoveryCodeURL: URL(string: "https://vault.bitwarden.com/#/recover-2fa")!,
                sendShareURL: URL(string: "https://send.bitwarden.com/#")!,
                settingsURL: URL(string: "https://vault.bitwarden.com/#/settings")!,
                setUpTwoFactorURL: URL(string: "https://vault.bitwarden.com/#/settings/security/two-factor")!,
                webVaultURL: URL(string: "https://vault.bitwarden.com")!,
            ),
        )
    }

    /// `init(environmentURLData:)` sets the URLs from the passed data when such data is the default EU.
    func test_init_environmentURLData_defaultEU() {
        let subject = EnvironmentURLs(
            environmentURLData: EnvironmentURLData.defaultEU,
        )
        XCTAssertEqual(
            subject,
            EnvironmentURLs(
                apiURL: URL(string: "https://api.bitwarden.eu")!,
                baseURL: URL(string: "https://vault.bitwarden.eu")!,
                changeEmailURL: URL(string: "https://vault.bitwarden.eu/#/settings/account")!,
                eventsURL: URL(string: "https://events.bitwarden.eu")!,
                iconsURL: URL(string: "https://icons.bitwarden.eu")!,
                identityURL: URL(string: "https://identity.bitwarden.eu")!,
                importItemsURL: URL(string: "https://vault.bitwarden.eu/#/tools/import")!,
                recoveryCodeURL: URL(string: "https://vault.bitwarden.eu/#/recover-2fa")!,
                sendShareURL: URL(string: "https://vault.bitwarden.eu/#/send")!,
                settingsURL: URL(string: "https://vault.bitwarden.eu/#/settings")!,
                setUpTwoFactorURL: URL(string: "https://vault.bitwarden.eu/#/settings/security/two-factor")!,
                webVaultURL: URL(string: "https://vault.bitwarden.eu")!,
            ),
        )
    }

    /// `init(environmentURLData:)` sets the URLs from the base URL if one is set and is not
    /// `.unitedStates` nor `.europe` region type.
    func test_init_environmentURLData_baseURL() {
        let subject = EnvironmentURLs(
            environmentURLData: EnvironmentURLData(base: URL(string: "https://example.com")!),
        )
        XCTAssertEqual(
            subject,
            EnvironmentURLs(
                apiURL: URL(string: "https://example.com/api")!,
                baseURL: URL(string: "https://example.com")!,
                changeEmailURL: URL(string: "https://example.com/#/settings/account")!,
                eventsURL: URL(string: "https://example.com/events")!,
                iconsURL: URL(string: "https://example.com/icons")!,
                identityURL: URL(string: "https://example.com/identity")!,
                importItemsURL: URL(string: "https://example.com/#/tools/import")!,
                recoveryCodeURL: URL(string: "https://example.com/#/recover-2fa")!,
                sendShareURL: URL(string: "https://example.com/#/send")!,
                settingsURL: URL(string: "https://example.com/#/settings")!,
                setUpTwoFactorURL: URL(string: "https://example.com/#/settings/security/two-factor")!,
                webVaultURL: URL(string: "https://example.com")!,
            ),
        )
    }

    /// `init(environmentURLData:)` defaults to the pre-defined EU URLs if the base URL matches the EU environment.
    func test_init_environmentURLData_baseURL_europe() {
        let subject = EnvironmentURLs(
            environmentURLData: EnvironmentURLData(base: URL(string: "https://vault.bitwarden.eu")!),
        )
        XCTAssertEqual(
            subject,
            EnvironmentURLs(
                apiURL: URL(string: "https://api.bitwarden.eu")!,
                baseURL: URL(string: "https://vault.bitwarden.eu")!,
                changeEmailURL: URL(string: "https://vault.bitwarden.eu/#/settings/account")!,
                eventsURL: URL(string: "https://events.bitwarden.eu")!,
                iconsURL: URL(string: "https://icons.bitwarden.eu")!,
                identityURL: URL(string: "https://identity.bitwarden.eu")!,
                importItemsURL: URL(string: "https://vault.bitwarden.eu/#/tools/import")!,
                recoveryCodeURL: URL(string: "https://vault.bitwarden.eu/#/recover-2fa")!,
                sendShareURL: URL(string: "https://vault.bitwarden.eu/#/send")!,
                settingsURL: URL(string: "https://vault.bitwarden.eu/#/settings")!,
                setUpTwoFactorURL: URL(string: "https://vault.bitwarden.eu/#/settings/security/two-factor")!,
                webVaultURL: URL(string: "https://vault.bitwarden.eu")!,
            ),
        )
    }

    /// `init(environmentURLData:)` defaults to the pre-defined US URLs if the base URL matches the US environment.
    func test_init_environmentURLData_baseURL_unitedStates() {
        let subject = EnvironmentURLs(
            environmentURLData: EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com")!),
        )
        XCTAssertEqual(
            subject,
            EnvironmentURLs(
                apiURL: URL(string: "https://api.bitwarden.com")!,
                baseURL: URL(string: "https://vault.bitwarden.com")!,
                changeEmailURL: URL(string: "https://vault.bitwarden.com/#/settings/account")!,
                eventsURL: URL(string: "https://events.bitwarden.com")!,
                iconsURL: URL(string: "https://icons.bitwarden.net")!,
                identityURL: URL(string: "https://identity.bitwarden.com")!,
                importItemsURL: URL(string: "https://vault.bitwarden.com/#/tools/import")!,
                recoveryCodeURL: URL(string: "https://vault.bitwarden.com/#/recover-2fa")!,
                sendShareURL: URL(string: "https://send.bitwarden.com/#")!,
                settingsURL: URL(string: "https://vault.bitwarden.com/#/settings")!,
                setUpTwoFactorURL: URL(string: "https://vault.bitwarden.com/#/settings/security/two-factor")!,
                webVaultURL: URL(string: "https://vault.bitwarden.com")!,
            ),
        )
    }

    /// `init(environmentURLData:)` sets the URLs from the base URL which includes a trailing slash.
    func test_init_environmentURLData_baseURLWithTrailingSlash() {
        let subject = EnvironmentURLs(
            environmentURLData: EnvironmentURLData(base: URL(string: "https://example.com/")!),
        )
        XCTAssertEqual(
            subject,
            EnvironmentURLs(
                apiURL: URL(string: "https://example.com/api")!,
                baseURL: URL(string: "https://example.com/")!,
                changeEmailURL: URL(string: "https://example.com/#/settings/account")!,
                eventsURL: URL(string: "https://example.com/events")!,
                iconsURL: URL(string: "https://example.com/icons")!,
                identityURL: URL(string: "https://example.com/identity")!,
                importItemsURL: URL(string: "https://example.com/#/tools/import")!,
                recoveryCodeURL: URL(string: "https://example.com/#/recover-2fa")!,
                sendShareURL: URL(string: "https://example.com/#/send")!,
                settingsURL: URL(string: "https://example.com/#/settings")!,
                setUpTwoFactorURL: URL(string: "https://example.com/#/settings/security/two-factor")!,
                webVaultURL: URL(string: "https://example.com/")!,
            ),
        )
    }

    /// `init(environmentURLData:)` sets the URLs based on the corresponding URL if there isn't a base URL.
    func test_init_environmentURLData_custom() {
        let subject = EnvironmentURLs(
            environmentURLData: EnvironmentURLData(
                api: URL(string: "https://api.example.com")!,
                events: URL(string: "https://events.example.com")!,
                icons: URL(string: "https://icons.example.com")!,
                identity: URL(string: "https://identity.example.com")!,
                webVault: URL(string: "https://example.com")!,
            ),
        )
        XCTAssertEqual(
            subject,
            EnvironmentURLs(
                apiURL: URL(string: "https://api.example.com")!,
                baseURL: URL(string: "https://vault.bitwarden.com")!,
                changeEmailURL: URL(string: "https://example.com/#/settings/account")!,
                eventsURL: URL(string: "https://events.example.com")!,
                iconsURL: URL(string: "https://icons.example.com")!,
                identityURL: URL(string: "https://identity.example.com")!,
                importItemsURL: URL(string: "https://example.com/#/tools/import")!,
                recoveryCodeURL: URL(string: "https://example.com/#/recover-2fa")!,
                sendShareURL: URL(string: "https://example.com/#/send")!,
                settingsURL: URL(string: "https://example.com/#/settings")!,
                setUpTwoFactorURL: URL(string: "https://example.com/#/settings/security/two-factor")!,
                webVaultURL: URL(string: "https://example.com")!,
            ),
        )
    }

    /// `init(environmentURLData:)` sets the URLs to default values if the URLs are empty.
    func test_init_environmentURLData_empty() {
        let subject = EnvironmentURLs(environmentURLData: EnvironmentURLData())
        XCTAssertEqual(
            subject,
            EnvironmentURLs(
                apiURL: URL(string: "https://api.bitwarden.com")!,
                baseURL: URL(string: "https://vault.bitwarden.com")!,
                changeEmailURL: URL(string: "https://vault.bitwarden.com")!,
                eventsURL: URL(string: "https://events.bitwarden.com")!,
                iconsURL: URL(string: "https://icons.bitwarden.net")!,
                identityURL: URL(string: "https://identity.bitwarden.com")!,
                importItemsURL: URL(string: "https://vault.bitwarden.com/#/tools/import")!,
                recoveryCodeURL: URL(string: "https://vault.bitwarden.com/#/recover-2fa")!,
                sendShareURL: URL(string: "https://send.bitwarden.com/#")!,
                settingsURL: URL(string: "https://vault.bitwarden.com")!,
                setUpTwoFactorURL: URL(string: "https://vault.bitwarden.com")!,
                webVaultURL: URL(string: "https://vault.bitwarden.com")!,
            ),
        )
    }
}
