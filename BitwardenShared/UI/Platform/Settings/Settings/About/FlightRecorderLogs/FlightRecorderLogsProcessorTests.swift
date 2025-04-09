import SnapshotTesting
import XCTest

@testable import BitwardenShared

class FlightRecorderLogsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var subject: FlightRecorderLogsProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()

        subject = FlightRecorderLogsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(),
            state: FlightRecorderLogsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }
}
