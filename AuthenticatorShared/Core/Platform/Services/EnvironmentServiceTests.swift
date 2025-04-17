import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import AuthenticatorShared

class EnvironmentServiceTests: XCTestCase {
    // MARK: Properties

    var subject: EnvironmentService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DefaultEnvironmentService()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// The default US URLs are returned.
    func test_defaultUrls() {
        XCTAssertEqual(subject.apiURL, URL(string: "https://api.bitwarden.com"))
        XCTAssertEqual(subject.baseURL, URL(string: "https://vault.bitwarden.com"))
        XCTAssertEqual(subject.changeEmailURL, URL(string: "https://vault.bitwarden.com/#/settings/account"))
        XCTAssertEqual(subject.eventsURL, URL(string: "https://events.bitwarden.com"))
        XCTAssertEqual(subject.iconsURL, URL(string: "https://icons.bitwarden.net"))
        XCTAssertEqual(subject.identityURL, URL(string: "https://identity.bitwarden.com"))
        XCTAssertEqual(subject.importItemsURL, URL(string: "https://vault.bitwarden.com/#/tools/import"))
        XCTAssertEqual(subject.recoveryCodeURL, URL(string: "https://vault.bitwarden.com/#/recover-2fa"))
        XCTAssertEqual(subject.region, .unitedStates)
        XCTAssertEqual(subject.sendShareURL, URL(string: "https://send.bitwarden.com/#"))
        XCTAssertEqual(subject.settingsURL, URL(string: "https://vault.bitwarden.com/#/settings"))
        // swiftlint:disable:next line_length
        XCTAssertEqual(subject.setUpTwoFactorURL, URL(string: "https://vault.bitwarden.com/#/settings/security/two-factor"))
        XCTAssertEqual(subject.webVaultURL, URL(string: "https://vault.bitwarden.com"))
    }
}
