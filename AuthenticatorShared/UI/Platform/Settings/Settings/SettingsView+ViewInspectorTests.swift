// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import ViewInspectorTestHelpers
import XCTest

// MARK: - SettingsViewTests

@testable import AuthenticatorShared

class SettingsViewTests: BitwardenTestCase {
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
    @MainActor
    func test_appThemeChanged_updateValue() throws {
        processor.state.appTheme = .light
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.theme)
        try menuField.select(newValue: AppTheme.dark)
        XCTAssertEqual(processor.dispatchedActions.last, .appThemeChanged(.dark))
    }

    /// Tapping the backup button dispatches the `.backupTapped` action.
    @MainActor
    func test_backupButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.backup)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .backupTapped)
    }

    /// Updating the value of the default save option sends the  `.defaultSaveOptionChanged()` action.
    @MainActor
    func test_defaultSaveOptionChanged_updateValue() throws {
        processor.state.shouldShowDefaultSaveOption = true
        processor.state.defaultSaveOption = .none
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.defaultSaveOption)
        try menuField.select(newValue: DefaultSaveOption.saveToBitwarden)
        XCTAssertEqual(processor.dispatchedActions.last, .defaultSaveChanged(.saveToBitwarden))
    }

    /// Tapping the export button dispatches the `.exportItemsTapped` action.
    @MainActor
    func test_exportButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.export)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .exportItemsTapped)
    }

    /// The flight recorder toggle turns logging on and off.
    @MainActor
    func test_flightRecorder_toggle_tap() async throws {
        let toggle = try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.flightRecorder)

        try toggle.tap()
        try await waitForAsync { !self.processor.effects.isEmpty }
        XCTAssertEqual(processor.effects, [.flightRecorder(.toggleFlightRecorder(true))])
        processor.effects.removeAll()

        processor.state.flightRecorderState.activeLog = FlightRecorderData.LogMetadata(
            duration: .eightHours,
            startDate: .now,
        )
        try toggle.tap()
        try await waitForAsync { !self.processor.effects.isEmpty }
        XCTAssertEqual(processor.effects, [.flightRecorder(.toggleFlightRecorder(false))])
    }

    /// Tapping the flight recorder view recorded logs button dispatches the
    /// `.viewFlightRecorderLogsTapped` action.
    @MainActor
    func test_flightRecorder_viewRecordedLogsButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.viewRecordedLogs)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .flightRecorder(.viewLogsTapped))
    }

    /// Tapping the help center button dispatches the `.helpCenterTapped` action.
    @MainActor
    func test_helpCenterButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.bitwardenHelpCenter)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .helpCenterTapped)
    }

    /// Tapping the language button dispatches the `.languageTapped` action.
    @MainActor
    func test_languageButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.language)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .languageTapped)
    }

    /// Tapping the privacy policy button dispatches the `.privacyPolicyTapped` action.
    @MainActor
    func test_privacyPolicyButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.privacyPolicy)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .privacyPolicyTapped)
    }

    /// Updating the value of the `sessionTimeoutValue` sends the  `.sessionTimeoutValueChanged()` action.
    @MainActor
    func test_sessionTimeoutValue_updateValue() throws {
        processor.state.biometricUnlockStatus = .available(.faceID, enabled: false, hasValidIntegrity: true)
        processor.state.sessionTimeoutValue = .never
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.sessionTimeout)
        try menuField.select(newValue: SessionTimeoutValue.fifteenMinutes)

        waitFor(!processor.effects.isEmpty)
        XCTAssertEqual(processor.effects.last, .sessionTimeoutValueChanged(.fifteenMinutes))
    }

    /// Tapping the sync with Bitwarden app button dispatches the `.syncWithBitwardenAppTapped` action.
    @MainActor
    func test_syncWithBitwardenButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.syncWithBitwardenApp)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .syncWithBitwardenAppTapped)
    }

    /// Tapping the tutorial button dispatches the `.tutorialTapped` action.
    @MainActor
    func test_tutorialButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.launchTutorial)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .tutorialTapped)
    }

    /// Tapping the version button dispatches the `.versionTapped` action.
    @MainActor
    func test_versionButton_tap() throws {
        let button = try subject.inspect().find(button: version)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .versionTapped)
    }
}
