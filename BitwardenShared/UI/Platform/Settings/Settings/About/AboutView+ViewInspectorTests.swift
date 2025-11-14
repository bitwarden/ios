// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenShared

class AboutViewTests: BitwardenTestCase {
    // MARK: Properties

    let copyrightText = "© Bitwarden Inc. 2015-2023"
    let version = "Version: 1.0.0 (1)"

    var processor: MockProcessor<AboutState, AboutAction, AboutEffect>!
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
    @MainActor
    func test_helpCenterButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.bitwardenHelpCenter)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .helpCenterTapped)
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

    /// Tapping the privacy policy button dispatches the `.privacyPolicyTapped` action.
    @MainActor
    func test_privacyPolicyButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.privacyPolicy)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .privacyPolicyTapped)
    }

    /// Tapping the learn about organizations button dispatches the `.learnAboutOrganizationsTapped` action.
    @MainActor
    func test_learnAboutOrganizationsButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.learnOrg)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .learnAboutOrganizationsTapped)
    }

    /// Tapping the version button dispatches the `.versionTapped` action.
    @MainActor
    func test_versionButton_tap() throws {
        let button = try subject.inspect().find(button: version)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .versionTapped)
    }

    /// Tapping the web vault button dispatches the `.webVaultTapped` action.
    @MainActor
    func test_webVaultButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.webVault)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .webVaultTapped)
    }
}
