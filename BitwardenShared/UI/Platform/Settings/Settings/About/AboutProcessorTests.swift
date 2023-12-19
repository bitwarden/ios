import XCTest

@testable import BitwardenShared

class AboutProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var subject: AboutProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute>()
        subject = AboutProcessor(coordinator: coordinator.asAnyCoordinator(), state: AboutState())
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// Toggling submit crash logs is reflected in the state.
    func test_toggleSubmitCrashLogs() {
        XCTAssertFalse(subject.state.isSubmitCrashLogsToggleOn)

        subject.receive(.toggleSubmitCrashLogs(true))

        XCTAssertTrue(subject.state.isSubmitCrashLogsToggleOn)
    }
}
