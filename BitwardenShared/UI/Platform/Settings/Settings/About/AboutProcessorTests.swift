import XCTest

@testable import BitwardenShared

class AboutProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var pasteboardService: MockPasteboardService!
    var subject: AboutProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute>()
        pasteboardService = MockPasteboardService()
        subject = AboutProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(pasteboardService: pasteboardService),
            state: AboutState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        pasteboardService = nil
        subject = nil
    }

    // MARK: Tests

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
        XCTAssertFalse(subject.state.isSubmitCrashLogsToggleOn)

        subject.receive(.toggleSubmitCrashLogs(true))

        XCTAssertTrue(subject.state.isSubmitCrashLogsToggleOn)
    }

    /// `receive(_:)` with action `.versionTapped` copies the version string to the pasteboard.
    func test_receive_versionTapped() {
        subject.receive(.versionTapped)
        let text = subject.state.copyrightText + "\n\n" + subject.state.version
        XCTAssertEqual(pasteboardService.copiedString, text)
        XCTAssertEqual(subject.state.toast?.text, Localizations.valueHasBeenCopied(Localizations.version))
    }
}
