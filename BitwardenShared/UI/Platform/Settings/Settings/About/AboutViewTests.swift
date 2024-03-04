import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AboutViewTests: BitwardenTestCase {
    // MARK: Properties

    let copyrightText = "© Bitwarden Inc. 2015-2023"
    let version = "Version: 1.0.0 (1)"

    var processor: MockProcessor<AboutState, AboutAction, Void>!
    var subject: AboutView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AboutState(copyrightText: copyrightText, version: version))
        let store = Store(processor: processor)

        subject = AboutView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the help center button dispatches the `.helpCenterTapped` action.
    func test_helpCenterButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.bitwardenHelpCenter)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .helpCenterTapped)
    }

    /// Tapping the privacy policy button dispatches the `.privacyPolicyTapped` action.
    func test_privacyPolicyButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.privacyPolicy)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .privacyPolicyTapped)
    }

    /// Tapping the learn about organizations button dispatches the `.learnAboutOrganizationsTapped` action.
    func test_learnAboutOrganizationsButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.learnOrg)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .learnAboutOrganizationsTapped)
    }

    /// Tapping the rate this app button dispatches the `.rateTheAppTapped` action.
    func test_rateAppButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.rateTheApp)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .rateTheAppTapped)
    }

    /// Tapping the version button dispatches the `.versionTapped` action.
    func test_versionButton_tap() throws {
        let button = try subject.inspect().find(button: version)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .versionTapped)
    }

    /// Tapping the web vault button dispatches the `.webVaultTapped` action.
    func test_webVaultButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.webVault)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .webVaultTapped)
    }

    // MARK: Snapshots

    /// The default view renders correctly.
    func test_snapshot_default() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
