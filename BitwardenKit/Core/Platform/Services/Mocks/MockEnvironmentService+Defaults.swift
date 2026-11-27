import Foundation

@testable import BitwardenKit

public extension MockEnvironmentService {
    /// Creates a `MockEnvironmentService` pre-configured with self-hosted `example.com` URLs.
    ///
    /// Sets every URL and the region, which the generated mock leaves unset.
    ///
    /// - Returns: A `MockEnvironmentService` with every URL and the region set.
    ///
    static func withDefaults() -> MockEnvironmentService {
        let mock = MockEnvironmentService()
        mock.apiURL = URL(string: "https://example.com/api")!
        mock.baseURL = URL(string: "https://example.com")!
        mock.changeEmailURL = URL(string: "https://example.com/#/settings/account")!
        mock.eventsURL = URL(string: "https://example.com/events")!
        mock.fillAssistRulesURL = URL(string: "https://example.com/fill-assist-rules")!
        mock.iconsURL = URL(string: "https://example.com/icons")!
        mock.identityURL = URL(string: "https://example.com/identity")!
        mock.importItemsURL = URL(string: "https://example.com/#/tools/import")!
        mock.manageSubscriptionURL = URL(string: "https://example.com/#/settings/subscription")!
        mock.proxyCookieRedirectConnectorURL = URL(string: "https://example.com/proxy-cookie-redirect-connector")!
        mock.recoveryCodeURL = URL(string: "https://example.com/#/recover-2fa")!
        mock.region = .selfHosted
        mock.sendShareURL = URL(string: "https://example.com/#/send")!
        mock.settingsURL = URL(string: "https://example.com/#/settings")!
        mock.setUpTwoFactorURL = URL(string: "https://example.com/#/settings/security/two-factor")!
        mock.upgradeToPremiumURL = URL(
            string: "https://example.com/#/settings/subscription/premium?callToAction=upgradeToPremium",
        )!
        mock.webVaultURL = URL(string: "https://example.com")!
        return mock
    }
}
