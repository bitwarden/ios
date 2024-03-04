import XCTest

@testable import BitwardenShared

class AboutProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var errorReporter: MockErrorReporter!
    var pasteboardService: MockPasteboardService!
    var subject: AboutProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()

        subject = AboutProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                pasteboardService: pasteboardService
            ),
            state: AboutState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        pasteboardService = nil
        subject = nil
    }

    // MARK: Tests

    /// `init` sets the correct crash logs setting.
    func test_init_loadsValues() {
        errorReporter.isEnabled = true

        subject = AboutProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter
            ),
            state: AboutState()
        )

        XCTAssertTrue(subject.state.isSubmitCrashLogsToggleOn)
    }

    /// `receive(_:)` with `.clearAppReviewURL` clears the app review URL in the state.
    func test_receive_clearAppReviewURL() {
        subject.state.appReviewUrl = .example
        subject.receive(.clearAppReviewURL)
        XCTAssertNil(subject.state.appReviewUrl)
    }

    /// `receive(_:)` with `.clearURL` clears the URL in the state.
    func test_receive_clearURL() {
        subject.state.url = .example
        subject.receive(.clearURL)
        XCTAssertNil(subject.state.url)
    }

    /// `receive(_:)` with `.helpCenterTapped` set the URL to open in the state.
    func test_receive_helpCenterTapped() {
        subject.receive(.helpCenterTapped)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.helpAndFeedback)
    }

    /// `receive(_:)` with `.learnAboutOrganizationsTapped` shows an alert for navigating to the website
    /// When `Continue` is tapped on the alert, sets the URL to open in the state.
    func test_receive_learnAboutOrganizationsTapped() async throws {
        subject.receive(.learnAboutOrganizationsTapped)

        guard case let .alert(alert) = coordinator.routes.last else {
            return XCTFail("Expected an `.alert` route, but found \(String(describing: coordinator.routes.last))")
        }

        try await alert.tapAction(title: Localizations.continue)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.aboutOrganizations)
    }

    /// `receive(_:)` with `.privacyPolicyTapped` shows an alert for navigating to the Privacy Policy
    /// When `Continue` is tapped on the alert, sets the URL to open in the state.
    func test_receive_privacyPolicyTapped() async throws {
        subject.receive(.privacyPolicyTapped)

        guard case let .alert(alert) = coordinator.routes.last else {
            return XCTFail("Expected an `.alert` route, but found \(String(describing: coordinator.routes.last))")
        }

        try await alert.tapAction(title: Localizations.continue)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.privacyPolicy)
    }

    /// `receive(_:)` with `.rateTheAppTapped` shows an alert for navigating to the app store.
    /// When `Continue` is tapped on the alert, the `appReviewUrl` is populated.
    func test_receive_rateTheAppTapped() async throws {
        subject.receive(.rateTheAppTapped)

        guard case let .alert(alert) = coordinator.routes.last else {
            return XCTFail("Expected an `.alert` route, but found \(String(describing: coordinator.routes.last))")
        }

        try await alert.tapAction(title: Localizations.continue)
        XCTAssertEqual(
            subject.state.appReviewUrl?.absoluteString,
            "https://itunes.apple.com/us/app/id1137397744?action=write-review"
        )
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    func test_receive_toastShown() {
        let toast = Toast(text: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// `receive(_:)` with action `.isSubmitCrashLogsToggleOn` updates the toggle value in the state.
    func test_receive_toggleSubmitCrashLogs() {
        errorReporter.isEnabled = false
        XCTAssertFalse(subject.state.isSubmitCrashLogsToggleOn)

        subject.receive(.toggleSubmitCrashLogs(true))

        XCTAssertTrue(subject.state.isSubmitCrashLogsToggleOn)
        XCTAssertTrue(errorReporter.isEnabled)
    }

    /// `receive(_:)` with action `.versionTapped` copies the version string to the pasteboard.
    func test_receive_versionTapped() {
        subject.receive(.versionTapped)
        let text = subject.state.copyrightText + "\n\n" + subject.state.version
        XCTAssertEqual(pasteboardService.copiedString, text)
        XCTAssertEqual(subject.state.toast?.text, Localizations.valueHasBeenCopied(Localizations.appInfo))
    }
}
