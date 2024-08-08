import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class AboutProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var aboutAdditionalInfo: MockAboutAdditionalInfo!
    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var pasteboardService: MockPasteboardService!
    var subject: AboutProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        aboutAdditionalInfo = MockAboutAdditionalInfo()
        coordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()

        subject = AboutProcessor(
            aboutAdditionalInfo: aboutAdditionalInfo,
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                environmentService: environmentService,
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                systemDevice: MockSystemDevice()
            ),
            state: AboutState()
        )
    }

    override func tearDown() {
        super.tearDown()

        aboutAdditionalInfo = nil
        coordinator = nil
        environmentService = nil
        errorReporter = nil
        pasteboardService = nil
        subject = nil
    }

    // MARK: Tests

    /// `init` sets the correct crash logs setting.
    func test_init_loadsValues() {
        errorReporter.isEnabled = true

        subject = AboutProcessor(
            aboutAdditionalInfo: aboutAdditionalInfo,
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                systemDevice: MockSystemDevice()
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

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.continue)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.aboutOrganizations)
    }

    /// `receive(_:)` with `.privacyPolicyTapped` shows an alert for navigating to the Privacy Policy
    /// When `Continue` is tapped on the alert, sets the URL to open in the state.
    func test_receive_privacyPolicyTapped() async throws {
        subject.receive(.privacyPolicyTapped)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.continue)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.privacyPolicy)
    }

    /// `receive(_:)` with `.rateTheAppTapped` shows an alert for navigating to the app store.
    /// When `Continue` is tapped on the alert, the `appReviewUrl` is populated.
    func test_receive_rateTheAppTapped() async throws {
        subject.receive(.rateTheAppTapped)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
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

    /// `receive(_:)` with action `.versionTapped` copies the copyright, the version string
    /// and device info to the pasteboard when no additional info is provided.
    func test_receive_versionTapped_noAdditionalInfo() {
        subject.receive(.versionTapped)
        XCTAssertEqual(
            pasteboardService.copiedString,
            """
            © Bitwarden Inc. 2015-2024

            Version: 2024.6.0 (1)

            -------- Device --------

            Model: iPhone14,2
            OS: iOS 16.4
            """
        )
        XCTAssertEqual(subject.state.toast?.text, Localizations.valueHasBeenCopied(Localizations.appInfo))
    }

    /// `receive(_:)` with action `.versionTapped` copies the copyright, the version string,
    /// device info and the additional info to the pasteboard when it's provided.
    func test_receive_versionTapped_withAdditionalInfo() {
        aboutAdditionalInfo.ciBuildInfo = [
            "Repository": "www.github.com/bitwarden/ios",
            "Branch": "test-branch",
        ]

        subject.receive(.versionTapped)
        XCTAssertEqual(
            pasteboardService.copiedString,
            """
            © Bitwarden Inc. 2015-2024

            Version: 2024.6.0 (1)

            -------- Device --------

            Model: iPhone14,2
            OS: iOS 16.4

            ------- CI Info --------

            Branch: test-branch
            Repository: www.github.com/bitwarden/ios
            """
        )
        XCTAssertEqual(subject.state.toast?.text, Localizations.valueHasBeenCopied(Localizations.appInfo))
    }

    /// `receive(_:)` with `.webVaultTapped` shows an alert for navigating to the web vault
    /// When `Continue` is tapped on the alert, sets the URL to open in the state.
    func test_receive_webVaultTapped() async throws {
        subject.receive(.webVaultTapped)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.continue)
        XCTAssertEqual(subject.state.url, environmentService.webVaultURL)
    }
}

class MockAboutAdditionalInfo: AboutAdditionalInfo {
    var ciBuildInfo: [String: String] = [:]
}
