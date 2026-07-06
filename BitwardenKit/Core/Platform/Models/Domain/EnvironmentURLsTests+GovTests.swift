import XCTest

@testable import BitwardenKit

extension EnvironmentURLsTests {
    // MARK: Tests

    /// `init(environmentURLData:)` sets the URLs from the passed data when such data is the default
    /// government cloud (FedRAMP) region.
    func test_init_environmentURLData_defaultGov() {
        let subject = EnvironmentURLs(
            environmentURLData: EnvironmentURLData.defaultGov,
        )
        XCTAssertEqual(
            subject,
            EnvironmentURLs(
                apiURL: URL(string: "https://api.bitwarden-gov.com")!,
                baseURL: URL(string: "https://vault.bitwarden-gov.com")!,
                changeEmailURL: URL(string: "https://vault.bitwarden-gov.com/#/settings/account")!,
                eventsURL: URL(string: "https://events.bitwarden-gov.com")!,
                fillAssistRulesURL: URL(string: "https://github.com/bitwarden/map-the-web/releases/latest/download")!,
                iconsURL: URL(string: "https://icons.bitwarden-gov.com")!,
                identityURL: URL(string: "https://identity.bitwarden-gov.com")!,
                importItemsURL: URL(string: "https://vault.bitwarden-gov.com/#/tools/import")!,
                manageSubscriptionURL: URL(string: "https://vault.bitwarden-gov.com/#/settings/subscription")!,
                proxyCookieRedirectConnectorURL: URL(
                    string: "https://vault.bitwarden-gov.com/proxy-cookie-redirect-connector.html",
                )!,
                recoveryCodeURL: URL(string: "https://vault.bitwarden-gov.com/#/recover-2fa")!,
                sendShareURL: URL(string: "https://send.bitwarden-gov.com/#")!,
                settingsURL: URL(string: "https://vault.bitwarden-gov.com/#/settings")!,
                setUpTwoFactorURL: URL(string: "https://vault.bitwarden-gov.com/#/settings/security/two-factor")!,
                upgradeToPremiumURL: URL(
                    // swiftlint:disable:next line_length
                    string: "https://vault.bitwarden-gov.com/#/settings/subscription/premium?callToAction=upgradeToPremium",
                )!,
                webVaultURL: URL(string: "https://vault.bitwarden-gov.com")!,
            ),
        )
    }

    /// `init(environmentURLData:)` defaults to the pre-defined government cloud (FedRAMP) URLs if the
    /// base URL matches the gov environment.
    func test_init_environmentURLData_baseURL_gov() {
        let subject = EnvironmentURLs(
            environmentURLData: EnvironmentURLData(base: URL(string: "https://vault.bitwarden-gov.com")!),
        )
        XCTAssertEqual(
            subject,
            EnvironmentURLs(
                apiURL: URL(string: "https://api.bitwarden-gov.com")!,
                baseURL: URL(string: "https://vault.bitwarden-gov.com")!,
                changeEmailURL: URL(string: "https://vault.bitwarden-gov.com/#/settings/account")!,
                eventsURL: URL(string: "https://events.bitwarden-gov.com")!,
                fillAssistRulesURL: URL(string: "https://github.com/bitwarden/map-the-web/releases/latest/download")!,
                iconsURL: URL(string: "https://icons.bitwarden-gov.com")!,
                identityURL: URL(string: "https://identity.bitwarden-gov.com")!,
                importItemsURL: URL(string: "https://vault.bitwarden-gov.com/#/tools/import")!,
                manageSubscriptionURL: URL(string: "https://vault.bitwarden-gov.com/#/settings/subscription")!,
                proxyCookieRedirectConnectorURL: URL(
                    string: "https://vault.bitwarden-gov.com/proxy-cookie-redirect-connector.html",
                )!,
                recoveryCodeURL: URL(string: "https://vault.bitwarden-gov.com/#/recover-2fa")!,
                sendShareURL: URL(string: "https://send.bitwarden-gov.com/#")!,
                settingsURL: URL(string: "https://vault.bitwarden-gov.com/#/settings")!,
                setUpTwoFactorURL: URL(string: "https://vault.bitwarden-gov.com/#/settings/security/two-factor")!,
                upgradeToPremiumURL: URL(
                    // swiftlint:disable:next line_length
                    string: "https://vault.bitwarden-gov.com/#/settings/subscription/premium?callToAction=upgradeToPremium",
                )!,
                webVaultURL: URL(string: "https://vault.bitwarden-gov.com")!,
            ),
        )
    }
}
