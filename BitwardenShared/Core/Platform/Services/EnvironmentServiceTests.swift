import XCTest

@testable import BitwardenShared

class EnvironmentServiceTests: XCTestCase {
    // MARK: Properties

    var stateService: MockStateService!
    var standardUserDefaults: UserDefaults!
    var subject: EnvironmentService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stateService = MockStateService()
        standardUserDefaults = UserDefaults(suiteName: "test")
        standardUserDefaults.removeObject(forKey: "com.apple.configuration.managed")

        subject = DefaultEnvironmentService(
            stateService: stateService,
            standardUserDefaults: standardUserDefaults
        )
    }

    override func tearDown() {
        super.tearDown()

        stateService = nil
        standardUserDefaults = nil
        subject = nil
    }

    // MARK: Tests

    /// The default US URLs are returned if the URLs haven't been loaded.
    func test_defaultUrls() {
        XCTAssertEqual(subject.apiURL, URL(string: "https://api.bitwarden.com"))
        XCTAssertEqual(subject.eventsURL, URL(string: "https://events.bitwarden.com"))
        XCTAssertEqual(subject.iconsURL, URL(string: "https://icons.bitwarden.net"))
        XCTAssertEqual(subject.identityURL, URL(string: "https://identity.bitwarden.com"))
        XCTAssertEqual(subject.importItemsURL, URL(string: "https://vault.bitwarden.com/#/tools/import"))
        XCTAssertEqual(subject.region, .unitedStates)
        XCTAssertEqual(subject.sendShareURL, URL(string: "https://send.bitwarden.com/#"))
        XCTAssertEqual(subject.settingsURL, URL(string: "https://vault.bitwarden.com/#/settings"))
        XCTAssertEqual(subject.webVaultURL, URL(string: "https://vault.bitwarden.com"))
    }

    /// `loadURLsForActiveAccount()` loads the URLs for the active account.
    func test_loadURLsForActiveAccount() async {
        let urls = EnvironmentUrlData(base: .example)
        let account = Account.fixture(settings: .fixture(environmentUrls: urls))
        stateService.activeAccount = account
        stateService.environmentUrls = [account.profile.userId: urls]

        await subject.loadURLsForActiveAccount()

        XCTAssertEqual(subject.apiURL, URL(string: "https://example.com/api"))
        XCTAssertEqual(subject.eventsURL, URL(string: "https://example.com/events"))
        XCTAssertEqual(subject.iconsURL, URL(string: "https://example.com/icons"))
        XCTAssertEqual(subject.identityURL, URL(string: "https://example.com/identity"))
        XCTAssertEqual(subject.importItemsURL, URL(string: "https://example.com/#/tools/import"))
        XCTAssertEqual(subject.region, .selfHosted)
        XCTAssertEqual(subject.sendShareURL, URL(string: "https://example.com/#/send"))
        XCTAssertEqual(subject.settingsURL, URL(string: "https://example.com/#/settings"))
        XCTAssertEqual(subject.webVaultURL, URL(string: "https://example.com"))
        XCTAssertEqual(stateService.preAuthEnvironmentUrls, urls)
    }

    /// `loadURLsForActiveAccount()` handles EU URLs
    func test_loadURLsForActiveAccount_europe() async {
        let urls = EnvironmentUrlData.defaultEU
        let account = Account.fixture(settings: .fixture(environmentUrls: urls))
        stateService.activeAccount = account
        stateService.environmentUrls = [account.profile.userId: urls]

        await subject.loadURLsForActiveAccount()

        XCTAssertEqual(subject.apiURL, URL(string: "https://api.bitwarden.eu"))
        XCTAssertEqual(subject.eventsURL, URL(string: "https://events.bitwarden.eu"))
        XCTAssertEqual(subject.iconsURL, URL(string: "https://icons.bitwarden.eu"))
        XCTAssertEqual(subject.identityURL, URL(string: "https://identity.bitwarden.eu"))
        XCTAssertEqual(subject.importItemsURL, URL(string: "https://vault.bitwarden.eu/#/tools/import"))
        XCTAssertEqual(subject.region, .europe)
        XCTAssertEqual(subject.sendShareURL, URL(string: "https://vault.bitwarden.eu/#/send"))
        XCTAssertEqual(subject.settingsURL, URL(string: "https://vault.bitwarden.eu/#/settings"))
        XCTAssertEqual(subject.webVaultURL, URL(string: "https://vault.bitwarden.eu"))
        XCTAssertEqual(stateService.preAuthEnvironmentUrls, urls)
    }

    /// `loadURLsForActiveAccount()` loads the managed config URLs.
    func test_loadURLsForActiveAccount_managedConfig() async throws {
        standardUserDefaults.setValue(
            ["baseEnvironmentUrl": "https://vault.example.com"],
            forKey: "com.apple.configuration.managed"
        )

        await subject.loadURLsForActiveAccount()

        let urls = try EnvironmentUrlData(base: XCTUnwrap(URL(string: "https://vault.example.com")))
        XCTAssertEqual(subject.apiURL, URL(string: "https://vault.example.com/api"))
        XCTAssertEqual(subject.eventsURL, URL(string: "https://vault.example.com/events"))
        XCTAssertEqual(subject.iconsURL, URL(string: "https://vault.example.com/icons"))
        XCTAssertEqual(subject.identityURL, URL(string: "https://vault.example.com/identity"))
        XCTAssertEqual(subject.importItemsURL, URL(string: "https://vault.example.com/#/tools/import"))
        XCTAssertEqual(subject.region, .selfHosted)
        XCTAssertEqual(subject.sendShareURL, URL(string: "https://vault.example.com/#/send"))
        XCTAssertEqual(subject.settingsURL, URL(string: "https://vault.example.com/#/settings"))
        XCTAssertEqual(subject.webVaultURL, URL(string: "https://vault.example.com"))
        XCTAssertEqual(stateService.preAuthEnvironmentUrls, urls)
    }

    /// `loadURLsForActiveAccount()` doesn't load the managed config URLs if there's an active
    /// account, but sets the pre-auth URLs to the managed config URLs.
    func test_loadURLsForActiveAccount_managedConfigActiveAccount() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.environmentUrls[account.profile.userId] = .defaultUS
        standardUserDefaults.setValue(
            ["baseEnvironmentUrl": "https://vault.example.com"],
            forKey: "com.apple.configuration.managed"
        )

        await subject.loadURLsForActiveAccount()

        XCTAssertEqual(subject.apiURL, URL(string: "https://api.bitwarden.com"))
        XCTAssertEqual(subject.eventsURL, URL(string: "https://events.bitwarden.com"))
        XCTAssertEqual(subject.iconsURL, URL(string: "https://icons.bitwarden.net"))
        XCTAssertEqual(subject.identityURL, URL(string: "https://identity.bitwarden.com"))
        XCTAssertEqual(subject.importItemsURL, URL(string: "https://vault.bitwarden.com/#/tools/import"))
        XCTAssertEqual(subject.region, .unitedStates)
        XCTAssertEqual(subject.sendShareURL, URL(string: "https://send.bitwarden.com/#"))
        XCTAssertEqual(subject.settingsURL, URL(string: "https://vault.bitwarden.com/#/settings"))
        XCTAssertEqual(subject.webVaultURL, URL(string: "https://vault.bitwarden.com"))

        let urls = try EnvironmentUrlData(base: XCTUnwrap(URL(string: "https://vault.example.com")))
        XCTAssertEqual(stateService.preAuthEnvironmentUrls, urls)
    }

    /// `loadURLsForActiveAccount()` loads the default URLs if there's no active account
    /// and no preauth URLs.
    func test_loadURLsForActiveAccount_noAccount() async {
        await subject.loadURLsForActiveAccount()

        XCTAssertEqual(subject.apiURL, URL(string: "https://api.bitwarden.com"))
        XCTAssertEqual(subject.eventsURL, URL(string: "https://events.bitwarden.com"))
        XCTAssertEqual(subject.iconsURL, URL(string: "https://icons.bitwarden.net"))
        XCTAssertEqual(subject.identityURL, URL(string: "https://identity.bitwarden.com"))
        XCTAssertEqual(subject.importItemsURL, URL(string: "https://vault.bitwarden.com/#/tools/import"))
        XCTAssertEqual(subject.region, .unitedStates)
        XCTAssertEqual(subject.sendShareURL, URL(string: "https://send.bitwarden.com/#"))
        XCTAssertEqual(subject.settingsURL, URL(string: "https://vault.bitwarden.com/#/settings"))
        XCTAssertEqual(subject.webVaultURL, URL(string: "https://vault.bitwarden.com"))
        XCTAssertEqual(stateService.preAuthEnvironmentUrls, .defaultUS)
    }

    /// `loadURLsForActiveAccount()` loads the preAuth URLs if there's no active account
    /// and there are preauth URLs.
    func test_loadURLsForActiveAccount_preAuth() async {
        let urls = EnvironmentUrlData(base: .example)
        stateService.preAuthEnvironmentUrls = urls

        await subject.loadURLsForActiveAccount()

        XCTAssertEqual(subject.apiURL, URL(string: "https://example.com/api"))
        XCTAssertEqual(subject.eventsURL, URL(string: "https://example.com/events"))
        XCTAssertEqual(subject.iconsURL, URL(string: "https://example.com/icons"))
        XCTAssertEqual(subject.identityURL, URL(string: "https://example.com/identity"))
        XCTAssertEqual(subject.importItemsURL, URL(string: "https://example.com/#/tools/import"))
        XCTAssertEqual(subject.region, .selfHosted)
        XCTAssertEqual(subject.sendShareURL, URL(string: "https://example.com/#/send"))
        XCTAssertEqual(subject.settingsURL, URL(string: "https://example.com/#/settings"))
        XCTAssertEqual(subject.webVaultURL, URL(string: "https://example.com"))
        XCTAssertEqual(stateService.preAuthEnvironmentUrls, urls)
    }

    /// `setPreAuthURLs(urls:)` sets the pre-auth URLs.
    func test_setPreAuthURLs() async {
        let urls = EnvironmentUrlData(base: .example)

        await subject.setPreAuthURLs(urls: urls)

        XCTAssertEqual(subject.apiURL, URL(string: "https://example.com/api"))
        XCTAssertEqual(subject.eventsURL, URL(string: "https://example.com/events"))
        XCTAssertEqual(subject.iconsURL, URL(string: "https://example.com/icons"))
        XCTAssertEqual(subject.identityURL, URL(string: "https://example.com/identity"))
        XCTAssertEqual(subject.importItemsURL, URL(string: "https://example.com/#/tools/import"))
        XCTAssertEqual(subject.region, .selfHosted)
        XCTAssertEqual(subject.sendShareURL, URL(string: "https://example.com/#/send"))
        XCTAssertEqual(subject.settingsURL, URL(string: "https://example.com/#/settings"))
        XCTAssertEqual(subject.webVaultURL, URL(string: "https://example.com"))
        XCTAssertEqual(stateService.preAuthEnvironmentUrls, urls)
    }
}
