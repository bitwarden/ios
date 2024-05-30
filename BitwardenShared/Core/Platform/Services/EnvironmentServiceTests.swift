import XCTest

@testable import BitwardenShared

class EnvironmentServiceTests: XCTestCase {
    // MARK: Properties

    var stateService: MockStateService!
    var subject: EnvironmentService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stateService = MockStateService()

        subject = DefaultEnvironmentService(stateService: stateService)
    }

    override func tearDown() {
        super.tearDown()

        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// The default US URLs are returned if the URLs haven't been loaded.
    func test_defaultUrls() {
        XCTAssertEqual(subject.apiURL, URL(string: "https://vault.bitwarden.com/api"))
        XCTAssertEqual(subject.eventsURL, URL(string: "https://vault.bitwarden.com/events"))
        XCTAssertEqual(subject.iconsURL, URL(string: "https://vault.bitwarden.com/icons"))
        XCTAssertEqual(subject.identityURL, URL(string: "https://vault.bitwarden.com/identity"))
        XCTAssertEqual(subject.importItemsURL, URL(string: "https://vault.bitwarden.com/#/tools/import"))
        XCTAssertEqual(subject.region, .unitedStates)
        XCTAssertEqual(subject.sendShareURL, URL(string: "https://vault.bitwarden.com/#/send"))
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
    }

    /// `loadURLsForActiveAccount()` handles EU URLs
    func test_loadURLsForActiveAccount_europe() async {
        let urls = EnvironmentUrlData.defaultEU
        let account = Account.fixture(settings: .fixture(environmentUrls: urls))
        stateService.activeAccount = account
        stateService.environmentUrls = [account.profile.userId: urls]

        await subject.loadURLsForActiveAccount()

        XCTAssertEqual(subject.apiURL, URL(string: "https://vault.bitwarden.eu/api"))
        XCTAssertEqual(subject.eventsURL, URL(string: "https://vault.bitwarden.eu/events"))
        XCTAssertEqual(subject.iconsURL, URL(string: "https://vault.bitwarden.eu/icons"))
        XCTAssertEqual(subject.identityURL, URL(string: "https://vault.bitwarden.eu/identity"))
        XCTAssertEqual(subject.importItemsURL, URL(string: "https://vault.bitwarden.eu/#/tools/import"))
        XCTAssertEqual(subject.region, .europe)
        XCTAssertEqual(subject.sendShareURL, URL(string: "https://vault.bitwarden.eu/#/send"))
        XCTAssertEqual(subject.settingsURL, URL(string: "https://vault.bitwarden.eu/#/settings"))
        XCTAssertEqual(subject.webVaultURL, URL(string: "https://vault.bitwarden.eu"))
    }

    /// `loadURLsForActiveAccount()` loads the default URLs if there's no active account.
    func test_loadURLsForActiveAccount_noAccount() async {
        await subject.loadURLsForActiveAccount()

        XCTAssertEqual(subject.apiURL, URL(string: "https://vault.bitwarden.com/api"))
        XCTAssertEqual(subject.eventsURL, URL(string: "https://vault.bitwarden.com/events"))
        XCTAssertEqual(subject.iconsURL, URL(string: "https://vault.bitwarden.com/icons"))
        XCTAssertEqual(subject.identityURL, URL(string: "https://vault.bitwarden.com/identity"))
        XCTAssertEqual(subject.importItemsURL, URL(string: "https://vault.bitwarden.com/#/tools/import"))
        XCTAssertEqual(subject.region, .unitedStates)
        XCTAssertEqual(subject.sendShareURL, URL(string: "https://vault.bitwarden.com/#/send"))
        XCTAssertEqual(subject.settingsURL, URL(string: "https://vault.bitwarden.com/#/settings"))
        XCTAssertEqual(subject.webVaultURL, URL(string: "https://vault.bitwarden.com"))
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
