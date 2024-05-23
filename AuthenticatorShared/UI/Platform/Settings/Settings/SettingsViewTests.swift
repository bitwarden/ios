import SnapshotTesting
import XCTest

// MARK: - SettingsViewTests

@testable import AuthenticatorShared

class SettingsViewTests: AuthenticatorTestCase {
    // MARK: Properties

    let copyrightText = "© Bitwarden Inc. 2015-2024"
    let version = "Version: 1.0.0 (1)"

    var processor: MockProcessor<SettingsState, SettingsAction, SettingsEffect>!
    var subject: SettingsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SettingsState(copyrightText: copyrightText, version: version))
        let store = Store(processor: processor)

        subject = SettingsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Updating the value of the app theme sends the  `.appThemeChanged()` action.
    func test_appThemeChanged_updateValue() throws {
        processor.state.appTheme = .light
        let menuField = try subject.inspect().find(settingsMenuField: Localizations.theme)
        try menuField.select(newValue: AppTheme.dark)
        XCTAssertEqual(processor.dispatchedActions.last, .appThemeChanged(.dark))
    }

    /// Tapping the backup button dispatches the `.backupTapped` action.
    func test_backupButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.backup)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .backupTapped)
    }

    /// Tapping the export button dispatches the `.exportItemsTapped` action.
    func test_exportButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.export)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .exportItemsTapped)
    }

    /// Tapping the help center button dispatches the `.helpCenterTapped` action.
    func test_helpCenterButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.bitwardenHelpCenter)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .helpCenterTapped)
    }

    /// Tapping the language button dispatches the `.languageTapped` action.
    func test_languageButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.language)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .languageTapped)
    }

    /// Tapping the privacy policy button dispatches the `.privacyPolicyTapped` action.
    func test_privacyPolicyButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.privacyPolicy)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .privacyPolicyTapped)
    }

    /// Tapping the tutorial button dispatches the `.tutorialTapped` action.
    func test_tutorialButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.launchTutorial)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .tutorialTapped)
    }

    /// Tapping the version button dispatches the `.versionTapped` action.
    func test_versionButton_tap() throws {
        let button = try subject.inspect().find(button: version)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .versionTapped)
    }

    /// Tests the view renders correctly.
    func test_viewRender() {
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }
}
