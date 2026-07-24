import Foundation
import Testing

@testable import BitwardenKit

struct EnvironmentURLsTests { // swiftlint:disable:this type_body_length
    // MARK: Tests

    /// `init(environmentURLData:)` sets the URLs from the passed data when such data is the default US.
    @Test
    func init_environmentURLData_defaultUS() {
        let subject = EnvironmentURLs(
            environmentURLData: EnvironmentURLData.defaultUS,
        )
        #expect(
            subject == EnvironmentURLs(
                apiURL: URL(string: "https://api.bitwarden.com")!,
                baseURL: URL(string: "https://vault.bitwarden.com")!,
                changeEmailURL: URL(string: "https://vault.bitwarden.com/#/settings/account")!,
                eventsURL: URL(string: "https://events.bitwarden.com")!,
                fillAssistRulesURL: URL(string: "https://github.com/bitwarden/map-the-web/releases/latest/download")!,
                iconsURL: URL(string: "https://icons.bitwarden.net")!,
                identityURL: URL(string: "https://identity.bitwarden.com")!,
                importItemsURL: URL(string: "https://vault.bitwarden.com/#/tools/import")!,
                manageSubscriptionURL: URL(string: "https://vault.bitwarden.com/#/settings/subscription")!,
                proxyCookieRedirectConnectorURL: URL(
                    string: "https://vault.bitwarden.com/proxy-cookie-redirect-connector.html",
                )!,
                recoveryCodeURL: URL(string: "https://vault.bitwarden.com/#/recover-2fa")!,
                sendShareURL: URL(string: "https://send.bitwarden.com/#")!,
                settingsURL: URL(string: "https://vault.bitwarden.com/#/settings")!,
                setUpTwoFactorURL: URL(string: "https://vault.bitwarden.com/#/settings/security/two-factor")!,
                upgradeToPremiumURL: URL(
                    string: "https://vault.bitwarden.com/#/settings/subscription/premium?callToAction=upgradeToPremium",
                )!,
                webVaultURL: URL(string: "https://vault.bitwarden.com")!,
            ),
        )
    }

    /// `init(environmentURLData:)` sets the URLs from the passed data when such data is the default EU.
    @Test
    func init_environmentURLData_defaultEU() {
        let subject = EnvironmentURLs(
            environmentURLData: EnvironmentURLData.defaultEU,
        )
        #expect(
            subject == EnvironmentURLs(
                apiURL: URL(string: "https://api.bitwarden.eu")!,
                baseURL: URL(string: "https://vault.bitwarden.eu")!,
                changeEmailURL: URL(string: "https://vault.bitwarden.eu/#/settings/account")!,
                eventsURL: URL(string: "https://events.bitwarden.eu")!,
                fillAssistRulesURL: URL(string: "https://github.com/bitwarden/map-the-web/releases/latest/download")!,
                iconsURL: URL(string: "https://icons.bitwarden.eu")!,
                identityURL: URL(string: "https://identity.bitwarden.eu")!,
                importItemsURL: URL(string: "https://vault.bitwarden.eu/#/tools/import")!,
                manageSubscriptionURL: URL(string: "https://vault.bitwarden.eu/#/settings/subscription")!,
                proxyCookieRedirectConnectorURL: URL(
                    string: "https://vault.bitwarden.eu/proxy-cookie-redirect-connector.html",
                )!,
                recoveryCodeURL: URL(string: "https://vault.bitwarden.eu/#/recover-2fa")!,
                sendShareURL: URL(string: "https://vault.bitwarden.eu/#/send")!,
                settingsURL: URL(string: "https://vault.bitwarden.eu/#/settings")!,
                setUpTwoFactorURL: URL(string: "https://vault.bitwarden.eu/#/settings/security/two-factor")!,
                upgradeToPremiumURL: URL(
                    string: "https://vault.bitwarden.eu/#/settings/subscription/premium?callToAction=upgradeToPremium",
                )!,
                webVaultURL: URL(string: "https://vault.bitwarden.eu")!,
            ),
        )
    }

    /// `init(environmentURLData:)` sets the URLs from the base URL if one is set and is not
    /// `.unitedStates` nor `.europe` region type.
    @Test
    func init_environmentURLData_baseURL() {
        let subject = EnvironmentURLs(
            environmentURLData: EnvironmentURLData(base: URL(string: "https://example.com")!),
        )
        #expect(
            subject == EnvironmentURLs(
                apiURL: URL(string: "https://example.com/api")!,
                baseURL: URL(string: "https://example.com")!,
                changeEmailURL: URL(string: "https://example.com/#/settings/account")!,
                eventsURL: URL(string: "https://example.com/events")!,
                fillAssistRulesURL: URL(string: "https://github.com/bitwarden/map-the-web/releases/latest/download")!,
                iconsURL: URL(string: "https://example.com/icons")!,
                identityURL: URL(string: "https://example.com/identity")!,
                importItemsURL: URL(string: "https://example.com/#/tools/import")!,
                manageSubscriptionURL: URL(string: "https://example.com/#/settings/subscription")!,
                proxyCookieRedirectConnectorURL: URL(
                    string: "https://example.com/proxy-cookie-redirect-connector.html",
                )!,
                recoveryCodeURL: URL(string: "https://example.com/#/recover-2fa")!,
                sendShareURL: URL(string: "https://example.com/#/send")!,
                settingsURL: URL(string: "https://example.com/#/settings")!,
                setUpTwoFactorURL: URL(string: "https://example.com/#/settings/security/two-factor")!,
                upgradeToPremiumURL: URL(
                    string: "https://example.com/#/settings/subscription/premium?callToAction=upgradeToPremium",
                )!,
                webVaultURL: URL(string: "https://example.com")!,
            ),
        )
    }

    /// `init(environmentURLData:)` defaults to the pre-defined EU URLs if the base URL matches the EU environment.
    @Test
    func init_environmentURLData_baseURL_europe() {
        let subject = EnvironmentURLs(
            environmentURLData: EnvironmentURLData(base: URL(string: "https://vault.bitwarden.eu")!),
        )
        #expect(
            subject == EnvironmentURLs(
                apiURL: URL(string: "https://api.bitwarden.eu")!,
                baseURL: URL(string: "https://vault.bitwarden.eu")!,
                changeEmailURL: URL(string: "https://vault.bitwarden.eu/#/settings/account")!,
                eventsURL: URL(string: "https://events.bitwarden.eu")!,
                fillAssistRulesURL: URL(string: "https://github.com/bitwarden/map-the-web/releases/latest/download")!,
                iconsURL: URL(string: "https://icons.bitwarden.eu")!,
                identityURL: URL(string: "https://identity.bitwarden.eu")!,
                importItemsURL: URL(string: "https://vault.bitwarden.eu/#/tools/import")!,
                manageSubscriptionURL: URL(string: "https://vault.bitwarden.eu/#/settings/subscription")!,
                proxyCookieRedirectConnectorURL: URL(
                    string: "https://vault.bitwarden.eu/proxy-cookie-redirect-connector.html",
                )!,
                recoveryCodeURL: URL(string: "https://vault.bitwarden.eu/#/recover-2fa")!,
                sendShareURL: URL(string: "https://vault.bitwarden.eu/#/send")!,
                settingsURL: URL(string: "https://vault.bitwarden.eu/#/settings")!,
                setUpTwoFactorURL: URL(string: "https://vault.bitwarden.eu/#/settings/security/two-factor")!,
                upgradeToPremiumURL: URL(
                    string: "https://vault.bitwarden.eu/#/settings/subscription/premium?callToAction=upgradeToPremium",
                )!,
                webVaultURL: URL(string: "https://vault.bitwarden.eu")!,
            ),
        )
    }

    /// `init(environmentURLData:)` defaults to the pre-defined US URLs if the base URL matches the US environment.
    @Test
    func init_environmentURLData_baseURL_unitedStates() {
        let subject = EnvironmentURLs(
            environmentURLData: EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com")!),
        )
        #expect(
            subject == EnvironmentURLs(
                apiURL: URL(string: "https://api.bitwarden.com")!,
                baseURL: URL(string: "https://vault.bitwarden.com")!,
                changeEmailURL: URL(string: "https://vault.bitwarden.com/#/settings/account")!,
                eventsURL: URL(string: "https://events.bitwarden.com")!,
                fillAssistRulesURL: URL(string: "https://github.com/bitwarden/map-the-web/releases/latest/download")!,
                iconsURL: URL(string: "https://icons.bitwarden.net")!,
                identityURL: URL(string: "https://identity.bitwarden.com")!,
                importItemsURL: URL(string: "https://vault.bitwarden.com/#/tools/import")!,
                manageSubscriptionURL: URL(string: "https://vault.bitwarden.com/#/settings/subscription")!,
                proxyCookieRedirectConnectorURL: URL(
                    string: "https://vault.bitwarden.com/proxy-cookie-redirect-connector.html",
                )!,
                recoveryCodeURL: URL(string: "https://vault.bitwarden.com/#/recover-2fa")!,
                sendShareURL: URL(string: "https://send.bitwarden.com/#")!,
                settingsURL: URL(string: "https://vault.bitwarden.com/#/settings")!,
                setUpTwoFactorURL: URL(string: "https://vault.bitwarden.com/#/settings/security/two-factor")!,
                upgradeToPremiumURL: URL(
                    string: "https://vault.bitwarden.com/#/settings/subscription/premium?callToAction=upgradeToPremium",
                )!,
                webVaultURL: URL(string: "https://vault.bitwarden.com")!,
            ),
        )
    }

    /// `init(environmentURLData:)` sets the URLs from the base URL which includes a trailing slash.
    @Test
    func init_environmentURLData_baseURLWithTrailingSlash() {
        let subject = EnvironmentURLs(
            environmentURLData: EnvironmentURLData(base: URL(string: "https://example.com/")!),
        )
        #expect(
            subject == EnvironmentURLs(
                apiURL: URL(string: "https://example.com/api")!,
                baseURL: URL(string: "https://example.com/")!,
                changeEmailURL: URL(string: "https://example.com/#/settings/account")!,
                eventsURL: URL(string: "https://example.com/events")!,
                fillAssistRulesURL: URL(string: "https://github.com/bitwarden/map-the-web/releases/latest/download")!,
                iconsURL: URL(string: "https://example.com/icons")!,
                identityURL: URL(string: "https://example.com/identity")!,
                importItemsURL: URL(string: "https://example.com/#/tools/import")!,
                manageSubscriptionURL: URL(string: "https://example.com/#/settings/subscription")!,
                proxyCookieRedirectConnectorURL: URL(
                    string: "https://example.com/proxy-cookie-redirect-connector.html",
                )!,
                recoveryCodeURL: URL(string: "https://example.com/#/recover-2fa")!,
                sendShareURL: URL(string: "https://example.com/#/send")!,
                settingsURL: URL(string: "https://example.com/#/settings")!,
                setUpTwoFactorURL: URL(string: "https://example.com/#/settings/security/two-factor")!,
                upgradeToPremiumURL: URL(
                    string: "https://example.com/#/settings/subscription/premium?callToAction=upgradeToPremium",
                )!,
                webVaultURL: URL(string: "https://example.com/")!,
            ),
        )
    }

    /// `init(environmentURLData:)` sets the URLs based on the corresponding URL if there isn't a base URL.
    @Test
    func init_environmentURLData_custom() {
        let subject = EnvironmentURLs(
            environmentURLData: EnvironmentURLData(
                api: URL(string: "https://api.example.com")!,
                events: URL(string: "https://events.example.com")!,
                icons: URL(string: "https://icons.example.com")!,
                identity: URL(string: "https://identity.example.com")!,
                webVault: URL(string: "https://example.com")!,
            ),
        )
        #expect(
            subject == EnvironmentURLs(
                apiURL: URL(string: "https://api.example.com")!,
                baseURL: URL(string: "https://vault.bitwarden.com")!,
                changeEmailURL: URL(string: "https://example.com/#/settings/account")!,
                eventsURL: URL(string: "https://events.example.com")!,
                fillAssistRulesURL: URL(string: "https://github.com/bitwarden/map-the-web/releases/latest/download")!,
                iconsURL: URL(string: "https://icons.example.com")!,
                identityURL: URL(string: "https://identity.example.com")!,
                importItemsURL: URL(string: "https://example.com/#/tools/import")!,
                manageSubscriptionURL: URL(string: "https://example.com/#/settings/subscription")!,
                proxyCookieRedirectConnectorURL: URL(
                    string: "https://example.com/proxy-cookie-redirect-connector.html",
                )!,
                recoveryCodeURL: URL(string: "https://example.com/#/recover-2fa")!,
                sendShareURL: URL(string: "https://example.com/#/send")!,
                settingsURL: URL(string: "https://example.com/#/settings")!,
                setUpTwoFactorURL: URL(string: "https://example.com/#/settings/security/two-factor")!,
                upgradeToPremiumURL: URL(
                    string: "https://example.com/#/settings/subscription/premium?callToAction=upgradeToPremium",
                )!,
                webVaultURL: URL(string: "https://example.com")!,
            ),
        )
    }

    /// `init(environmentURLData:)` sets the URLs to default values if the URLs are empty.
    @Test
    func init_environmentURLData_empty() {
        let subject = EnvironmentURLs(environmentURLData: EnvironmentURLData())
        #expect(
            subject == EnvironmentURLs(
                apiURL: URL(string: "https://api.bitwarden.com")!,
                baseURL: URL(string: "https://vault.bitwarden.com")!,
                changeEmailURL: URL(string: "https://vault.bitwarden.com")!,
                eventsURL: URL(string: "https://events.bitwarden.com")!,
                fillAssistRulesURL: URL(string: "https://github.com/bitwarden/map-the-web/releases/latest/download")!,
                iconsURL: URL(string: "https://icons.bitwarden.net")!,
                identityURL: URL(string: "https://identity.bitwarden.com")!,
                importItemsURL: URL(string: "https://vault.bitwarden.com/#/tools/import")!,
                manageSubscriptionURL: URL(string: "https://vault.bitwarden.com")!,
                proxyCookieRedirectConnectorURL: URL(string: "https://vault.bitwarden.com")!,
                recoveryCodeURL: URL(string: "https://vault.bitwarden.com/#/recover-2fa")!,
                sendShareURL: URL(string: "https://send.bitwarden.com/#")!,
                settingsURL: URL(string: "https://vault.bitwarden.com")!,
                setUpTwoFactorURL: URL(string: "https://vault.bitwarden.com")!,
                upgradeToPremiumURL: URL(string: "https://vault.bitwarden.com")!,
                webVaultURL: URL(string: "https://vault.bitwarden.com")!,
            ),
        )
    }

    /// `init(environmentURLData:)` preserves a server-provided `fillAssistRulesUrl` even when the
    /// region maps to a US/EU default (which has `fillAssistRulesUrl = nil`).
    @Test
    func init_environmentURLData_fillAssistRulesURL_preservedForCloudRegion() {
        let customFillAssistURL = URL(string: "https://custom.example.com/fill-assist")!
        let usData = EnvironmentURLData(
            base: URL(string: "https://vault.bitwarden.com")!,
            fillAssistRulesUrl: customFillAssistURL,
        )

        let subject = EnvironmentURLs(environmentURLData: usData)

        #expect(subject.fillAssistRulesURL == customFillAssistURL)
    }

    /// `region` resolves the base URL to the matching region.
    @Test
    func region() {
        #expect(EnvironmentURLs(environmentURLData: .defaultUS).region == .unitedStates)
        #expect(EnvironmentURLs(environmentURLData: .defaultEU).region == .europe)
        #expect(
            EnvironmentURLs(environmentURLData: EnvironmentURLData(base: URL(string: "https://bitwarden.pw")!))
                .region == .internal,
        )
        #expect(
            EnvironmentURLs(
                environmentURLData: EnvironmentURLData(base: URL(string: "https://selfhosted.com")!),
            ).region == .selfHosted,
        )
    }
}
