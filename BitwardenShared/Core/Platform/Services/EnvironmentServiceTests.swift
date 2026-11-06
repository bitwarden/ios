import BitwardenKit
import BitwardenKitMocks
import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

@Suite(.serialized)
struct EnvironmentServiceTests { // swiftlint:disable:this type_body_length
    // MARK: Properties

    let errorReporter: MockErrorReporter
    let stateService: MockStateService
    let standardUserDefaults: UserDefaults
    let subject: EnvironmentService

    // MARK: Setup & Teardown

    init() {
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        standardUserDefaults = UserDefaults(suiteName: "test")!
        standardUserDefaults.removeObject(forKey: "com.apple.configuration.managed")

        subject = DefaultEnvironmentService(
            errorReporter: errorReporter,
            stateService: stateService,
            standardUserDefaults: standardUserDefaults,
        )
    }

    // MARK: Tests

    /// `setPreAuthURLs(urls:)` and property reads do not produce a data race under concurrent access.
    @Test
    func concurrentReadWrite_noDataRace() async {
        let urls = EnvironmentURLData(base: .example)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 50 {
                group.addTask { await subject.setPreAuthURLs(urls: urls) }
                group.addTask { _ = subject.apiURL }
                group.addTask { _ = subject.clientCertificateFingerprint }
            }
        }
    }

    /// `apiURL` and other URL properties return US default values before URLs are loaded.
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
        #expect(subject.webVaultURL == URL(string: "https://vault.bitwarden.com"))
    }

    /// `loadURLsForActiveAccount()` loads the URLs for the active account.
    @Test
    func loadURLsForActiveAccount() async {
        let urls = EnvironmentURLData(base: .example)
        let account = Account.fixture(settings: .fixture(environmentURLs: urls))
        stateService.activeAccount = account
        stateService.environmentURLs = [account.profile.userId: urls]

        await subject.loadURLsForActiveAccount()

        #expect(subject.apiURL == URL(string: "https://example.com/api"))
        #expect(subject.baseURL == URL(string: "https://example.com"))
        #expect(subject.changeEmailURL == URL(string: "https://example.com/#/settings/account"))
        #expect(subject.eventsURL == URL(string: "https://example.com/events"))
        #expect(subject.iconsURL == URL(string: "https://example.com/icons"))
        #expect(subject.identityURL == URL(string: "https://example.com/identity"))
        #expect(subject.importItemsURL == URL(string: "https://example.com/#/tools/import"))
        #expect(
            subject.proxyCookieRedirectConnectorURL
                == URL(string: "https://example.com/proxy-cookie-redirect-connector.html"),
        )
        #expect(subject.recoveryCodeURL == URL(string: "https://example.com/#/recover-2fa"))
        #expect(subject.region == .selfHosted)
        #expect(subject.sendShareURL == URL(string: "https://example.com/#/send"))
        #expect(subject.settingsURL == URL(string: "https://example.com/#/settings"))
        #expect(subject.setUpTwoFactorURL == URL(string: "https://example.com/#/settings/security/two-factor"))
        #expect(subject.webVaultURL == URL(string: "https://example.com"))
        #expect(stateService.preAuthEnvironmentURLs == urls)

        #expect(errorReporter.region?.region == "Self-Hosted")
        #expect(errorReporter.region?.isPreAuth == false)
    }

    /// `loadURLsForActiveAccount()` loads the client certificate fingerprint from the account URLs.
    @Test
    func loadURLsForActiveAccount_clientCertificateFingerprint() async {
        let urls = EnvironmentURLData(base: .example, clientCertificateFingerprint: "test-fingerprint")
        let account = Account.fixture(settings: .fixture(environmentURLs: urls))
        stateService.activeAccount = account
        stateService.environmentURLs = [account.profile.userId: urls]

        await subject.loadURLsForActiveAccount()

        #expect(subject.clientCertificateFingerprint == "test-fingerprint")
    }

    /// `loadURLsForActiveAccount()` handles EU URLs.
    @Test
    func loadURLsForActiveAccount_europe() async {
        let urls = EnvironmentURLData.defaultEU
        let account = Account.fixture(settings: .fixture(environmentURLs: urls))
        stateService.activeAccount = account
        stateService.environmentURLs = [account.profile.userId: urls]

        await subject.loadURLsForActiveAccount()

        #expect(subject.apiURL == URL(string: "https://api.bitwarden.eu"))
        #expect(subject.baseURL == URL(string: "https://vault.bitwarden.eu"))
        #expect(subject.changeEmailURL == URL(string: "https://vault.bitwarden.eu/#/settings/account"))
        #expect(subject.eventsURL == URL(string: "https://events.bitwarden.eu"))
        #expect(subject.iconsURL == URL(string: "https://icons.bitwarden.eu"))
        #expect(subject.identityURL == URL(string: "https://identity.bitwarden.eu"))
        #expect(subject.importItemsURL == URL(string: "https://vault.bitwarden.eu/#/tools/import"))
        #expect(
            subject.proxyCookieRedirectConnectorURL
                == URL(string: "https://vault.bitwarden.eu/proxy-cookie-redirect-connector.html"),
        )
        #expect(subject.recoveryCodeURL == URL(string: "https://vault.bitwarden.eu/#/recover-2fa"))
        #expect(subject.region == .europe)
        #expect(subject.sendShareURL == URL(string: "https://vault.bitwarden.eu/#/send"))
        #expect(subject.settingsURL == URL(string: "https://vault.bitwarden.eu/#/settings"))
        #expect(
            subject.setUpTwoFactorURL
                == URL(string: "https://vault.bitwarden.eu/#/settings/security/two-factor"),
        )
        #expect(subject.webVaultURL == URL(string: "https://vault.bitwarden.eu"))
        #expect(stateService.preAuthEnvironmentURLs == urls)

        #expect(errorReporter.region?.region == "EU")
        #expect(errorReporter.region?.isPreAuth == false)
    }

    /// `loadURLsForActiveAccount()` loads the managed config URLs.
    @Test
    func loadURLsForActiveAccount_managedConfig() async throws {
        standardUserDefaults.setValue(
            ["baseEnvironmentUrl": "https://vault.example.com"],
            forKey: "com.apple.configuration.managed",
        )

        await subject.loadURLsForActiveAccount()

        let urls = try EnvironmentURLData(base: #require(URL(string: "https://vault.example.com")))
        #expect(subject.apiURL == URL(string: "https://vault.example.com/api"))
        #expect(subject.baseURL == URL(string: "https://vault.example.com"))
        #expect(subject.changeEmailURL == URL(string: "https://vault.example.com/#/settings/account"))
        #expect(subject.eventsURL == URL(string: "https://vault.example.com/events"))
        #expect(subject.iconsURL == URL(string: "https://vault.example.com/icons"))
        #expect(subject.identityURL == URL(string: "https://vault.example.com/identity"))
        #expect(subject.importItemsURL == URL(string: "https://vault.example.com/#/tools/import"))
        #expect(
            subject.proxyCookieRedirectConnectorURL
                == URL(string: "https://vault.example.com/proxy-cookie-redirect-connector.html"),
        )
        #expect(subject.recoveryCodeURL == URL(string: "https://vault.example.com/#/recover-2fa"))
        #expect(subject.region == .selfHosted)
        #expect(subject.sendShareURL == URL(string: "https://vault.example.com/#/send"))
        #expect(subject.settingsURL == URL(string: "https://vault.example.com/#/settings"))
        #expect(
            subject.setUpTwoFactorURL
                == URL(string: "https://vault.example.com/#/settings/security/two-factor"),
        )
        #expect(subject.webVaultURL == URL(string: "https://vault.example.com"))
        #expect(stateService.preAuthEnvironmentURLs == urls)
    }

    /// `loadURLsForActiveAccount()` doesn't load the managed config URLs if there's an active
    /// account, but sets the pre-auth URLs to the managed config URLs.
    @Test
    func loadURLsForActiveAccount_managedConfigActiveAccount() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.environmentURLs[account.profile.userId] = .defaultUS
        standardUserDefaults.setValue(
            ["baseEnvironmentUrl": "https://vault.example.com"],
            forKey: "com.apple.configuration.managed",
        )

        await subject.loadURLsForActiveAccount()

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
        #expect(subject.webVaultURL == URL(string: "https://vault.bitwarden.com"))

        let urls = try EnvironmentURLData(base: #require(URL(string: "https://vault.example.com")))
        #expect(stateService.preAuthEnvironmentURLs == urls)
    }

    /// `loadURLsForActiveAccount()` loads the default URLs if there's no active account
    /// and no preauth URLs.
    @Test
    func loadURLsForActiveAccount_noAccount() async {
        await subject.loadURLsForActiveAccount()

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
        #expect(subject.webVaultURL == URL(string: "https://vault.bitwarden.com"))
        #expect(stateService.preAuthEnvironmentURLs == .defaultUS)

        #expect(errorReporter.region?.region == "US")
        #expect(errorReporter.region?.isPreAuth == false)
    }

    /// `loadURLsForActiveAccount()` loads the preAuth URLs if there's no active account
    /// and there are preauth URLs.
    @Test
    func loadURLsForActiveAccount_preAuth() async {
        let urls = EnvironmentURLData(base: .example)
        stateService.preAuthEnvironmentURLs = urls

        await subject.loadURLsForActiveAccount()

        #expect(subject.apiURL == URL(string: "https://example.com/api"))
        #expect(subject.baseURL == URL(string: "https://example.com"))
        #expect(subject.changeEmailURL == URL(string: "https://example.com/#/settings/account"))
        #expect(subject.eventsURL == URL(string: "https://example.com/events"))
        #expect(subject.iconsURL == URL(string: "https://example.com/icons"))
        #expect(subject.identityURL == URL(string: "https://example.com/identity"))
        #expect(subject.importItemsURL == URL(string: "https://example.com/#/tools/import"))
        #expect(
            subject.proxyCookieRedirectConnectorURL
                == URL(string: "https://example.com/proxy-cookie-redirect-connector.html"),
        )
        #expect(subject.recoveryCodeURL == URL(string: "https://example.com/#/recover-2fa"))
        #expect(subject.region == .selfHosted)
        #expect(subject.sendShareURL == URL(string: "https://example.com/#/send"))
        #expect(subject.settingsURL == URL(string: "https://example.com/#/settings"))
        #expect(subject.setUpTwoFactorURL == URL(string: "https://example.com/#/settings/security/two-factor"))
        #expect(subject.webVaultURL == URL(string: "https://example.com"))
        #expect(stateService.preAuthEnvironmentURLs == urls)

        #expect(errorReporter.region?.region == "Self-Hosted")
        #expect(errorReporter.region?.isPreAuth == false)
    }

    /// `region` resolves a `bitwarden.pw` environment (including subdomains) to `.internal`.
    @Test
    func region_internal() async {
        await subject.setPreAuthURLs(urls: EnvironmentURLData(base: URL(string: "https://qa-team.sh.bitwarden.pw")!))

        #expect(subject.region == .internal)
        #expect(errorReporter.region?.region == "Internal")
        #expect(errorReporter.region?.isPreAuth == true)
    }

    /// `setPreAuthURLs(urls:)` sets the pre-auth URLs.
    @Test
    func setPreAuthURLs() async {
        let urls = EnvironmentURLData(base: .example)

        await subject.setPreAuthURLs(urls: urls)

        #expect(subject.apiURL == URL(string: "https://example.com/api"))
        #expect(subject.baseURL == URL(string: "https://example.com"))
        #expect(subject.changeEmailURL == URL(string: "https://example.com/#/settings/account"))
        #expect(subject.eventsURL == URL(string: "https://example.com/events"))
        #expect(subject.iconsURL == URL(string: "https://example.com/icons"))
        #expect(subject.identityURL == URL(string: "https://example.com/identity"))
        #expect(subject.importItemsURL == URL(string: "https://example.com/#/tools/import"))
        #expect(
            subject.proxyCookieRedirectConnectorURL
                == URL(string: "https://example.com/proxy-cookie-redirect-connector.html"),
        )
        #expect(subject.recoveryCodeURL == URL(string: "https://example.com/#/recover-2fa"))
        #expect(subject.region == .selfHosted)
        #expect(subject.sendShareURL == URL(string: "https://example.com/#/send"))
        #expect(subject.settingsURL == URL(string: "https://example.com/#/settings"))
        #expect(subject.setUpTwoFactorURL == URL(string: "https://example.com/#/settings/security/two-factor"))
        #expect(subject.webVaultURL == URL(string: "https://example.com"))
        #expect(stateService.preAuthEnvironmentURLs == urls)
        #expect(errorReporter.region?.region == "Self-Hosted")
        #expect(errorReporter.region?.isPreAuth == true)
    }

    /// `setPreAuthURLs(urls:)` sets the client certificate fingerprint from the pre-auth URLs.
    @Test
    func setPreAuthURLs_clientCertificateFingerprint() async {
        let urls = EnvironmentURLData(base: .example, clientCertificateFingerprint: "test-fingerprint")

        await subject.setPreAuthURLs(urls: urls)

        #expect(subject.clientCertificateFingerprint == "test-fingerprint")
    }
}
