import BitwardenKit
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

extension EnvironmentServiceTests {
    // MARK: Tests

    /// `loadURLsForActiveAccount()` handles government cloud (FedRAMP) URLs
    func test_loadURLsForActiveAccount_gov() async {
        let urls = EnvironmentURLData.defaultGov
        let account = Account.fixture(settings: .fixture(environmentURLs: urls))
        stateService.activeAccount = account
        stateService.environmentURLs = [account.profile.userId: urls]

        await subject.loadURLsForActiveAccount()

        XCTAssertEqual(subject.apiURL, URL(string: "https://api.bitwarden-gov.com"))
        XCTAssertEqual(subject.baseURL, URL(string: "https://vault.bitwarden-gov.com"))
        XCTAssertEqual(subject.changeEmailURL, URL(string: "https://vault.bitwarden-gov.com/#/settings/account"))
        XCTAssertEqual(subject.eventsURL, URL(string: "https://events.bitwarden-gov.com"))
        XCTAssertEqual(subject.iconsURL, URL(string: "https://icons.bitwarden-gov.com"))
        XCTAssertEqual(subject.identityURL, URL(string: "https://identity.bitwarden-gov.com"))
        XCTAssertEqual(subject.importItemsURL, URL(string: "https://vault.bitwarden-gov.com/#/tools/import"))
        // swiftlint:disable:next line_length
        XCTAssertEqual(subject.proxyCookieRedirectConnectorURL, URL(string: "https://vault.bitwarden-gov.com/proxy-cookie-redirect-connector.html"))
        XCTAssertEqual(subject.recoveryCodeURL, URL(string: "https://vault.bitwarden-gov.com/#/recover-2fa"))
        XCTAssertEqual(subject.region, .gov)
        XCTAssertEqual(subject.sendShareURL, URL(string: "https://send.bitwarden-gov.com/#"))
        XCTAssertEqual(subject.settingsURL, URL(string: "https://vault.bitwarden-gov.com/#/settings"))
        // swiftlint:disable:next line_length
        XCTAssertEqual(subject.setUpTwoFactorURL, URL(string: "https://vault.bitwarden-gov.com/#/settings/security/two-factor"))
        XCTAssertEqual(subject.webVaultURL, URL(string: "https://vault.bitwarden-gov.com"))
        XCTAssertEqual(stateService.preAuthEnvironmentURLs, urls)

        XCTAssertEqual(errorReporter.region?.region, "Gov")
        XCTAssertEqual(errorReporter.region?.isPreAuth, false)
    }
}
