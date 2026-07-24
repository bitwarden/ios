import BitwardenKit
import BitwardenKitMocks
import Foundation
import Testing

@testable import AuthenticatorShared

struct EnvironmentServiceTests {
    // MARK: Properties

    let subject: EnvironmentService

    // MARK: Setup & Teardown

    init() {
        subject = DefaultEnvironmentService()
    }

    // MARK: Tests

    /// `apiURL` and other URL properties return US default values.
    @Test
    func defaultUrls() {
        #expect(subject.apiURL == URL(string: "https://api.bitwarden.com"))
        #expect(subject.baseURL == URL(string: "https://vault.bitwarden.com"))
        #expect(subject.changeEmailURL == URL(string: "https://vault.bitwarden.com/#/settings/account"))
        #expect(subject.eventsURL == URL(string: "https://events.bitwarden.com"))
        #expect(subject.iconsURL == URL(string: "https://icons.bitwarden.net"))
        #expect(subject.identityURL == URL(string: "https://identity.bitwarden.com"))
        #expect(subject.importItemsURL == URL(string: "https://vault.bitwarden.com/#/tools/import"))
        #expect(
            subject.proxyCookieRedirectConnectorURL
                == URL(string: "https://vault.bitwarden.com/proxy-cookie-redirect-connector.html"),
        )
        #expect(subject.recoveryCodeURL == URL(string: "https://vault.bitwarden.com/#/recover-2fa"))
        #expect(subject.region == .unitedStates)
        #expect(subject.sendShareURL == URL(string: "https://send.bitwarden.com/#"))
        #expect(subject.settingsURL == URL(string: "https://vault.bitwarden.com/#/settings"))
        #expect(
            subject.setUpTwoFactorURL
                == URL(string: "https://vault.bitwarden.com/#/settings/security/two-factor"),
        )
        #expect(
            subject.fillAssistRulesURL
                == URL(string: "https://github.com/bitwarden/map-the-web/releases/latest/download"),
        )
        #expect(subject.webVaultURL == URL(string: "https://vault.bitwarden.com"))
    }
}
