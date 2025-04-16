import BitwardenKitMocks
import SnapshotTesting
import TestHelpers
import XCTest

@testable import BitwardenShared

class FlightRecorderLogsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var errorReporter: MockErrorReporter!
    var flightRecorder: MockFlightRecorder!
    var subject: FlightRecorderLogsProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        flightRecorder = MockFlightRecorder()

        subject = FlightRecorderLogsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                flightRecorder: flightRecorder
            ),
            state: FlightRecorderLogsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        flightRecorder = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.loadData` fetches the list of logs from the flight recorder.
    @MainActor
    func test_perform_loadData() async {
        let logs: [FlightRecorderLogMetadata] = [
            .fixture(duration: .eightHours),
            .fixture(duration: .twentyFourHours),
        ]
        flightRecorder.fetchLogsResult = .success(logs)

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.logs, logs)
    }

    /// `perform(_:)` with `.loadData` displays an error alert if an error occurs.
    @MainActor
    func test_perform_loadData_error() async {
        flightRecorder.fetchLogsResult = .failure(BitwardenTestError.example)

        await subject.perform(.loadData)

        XCTAssertTrue(subject.state.logs.isEmpty)
        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }
}
