import XCTest

@testable import BitwardenShared

class OtherSettingsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var subject: OtherSettingsProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute>()
        subject = OtherSettingsProcessor(coordinator: coordinator.asAnyCoordinator(), state: OtherSettingsState())
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// Toggling allow sync on refresh is reflected in the state.
    func test_toggleAllowSyncOnRefresh() {
        XCTAssertFalse(subject.state.isAllowSyncOnRefreshToggleOn)

        subject.receive(.toggleAllowSyncOnRefresh(true))

        XCTAssertTrue(subject.state.isAllowSyncOnRefreshToggleOn)
    }

    /// Toggling connect to watch is reflected in the state.
    func test_toggleConnectToWatch() {
        XCTAssertFalse(subject.state.isConnectToWatchToggleOn)

        subject.receive(.toggleConnectToWatch(true))

        XCTAssertTrue(subject.state.isConnectToWatchToggleOn)
    }
}
