import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenKit

class EnableFlightRecorderProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<FlightRecorderRoute, Void>!
    var errorReporter: MockErrorReporter!
    var flightRecorder: MockFlightRecorder!
    var subject: EnableFlightRecorderProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        flightRecorder = MockFlightRecorder()

        subject = EnableFlightRecorderProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                flightRecorder: flightRecorder,
            ),
            state: EnableFlightRecorderState(),
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

    /// `perform(_:)` with `.save` dismisses the view.
    @MainActor
    func test_perform_save() async {
        await subject.perform(.save)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
        XCTAssertTrue(flightRecorder.enableFlightRecorderCalled)
        XCTAssertEqual(flightRecorder.enableFlightRecorderDuration, .twentyFourHours)
    }

    /// `perform(_:)` with `.save` dismisses the view with a modified duration.
    @MainActor
    func test_perform_save_eightHourDuration() async {
        subject.state.loggingDuration = .eightHours

        await subject.perform(.save)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
        XCTAssertTrue(flightRecorder.enableFlightRecorderCalled)
        XCTAssertEqual(flightRecorder.enableFlightRecorderDuration, .eightHours)
    }

    /// `perform(_:)` with `.save` shows an alert if an error occurs.
    @MainActor
    func test_perform_save_error() async {
        flightRecorder.enableFlightRecorderResult = .failure(BitwardenTestError.example)

        await subject.perform(.save)

        XCTAssertTrue(coordinator.routes.isEmpty)
        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertTrue(flightRecorder.enableFlightRecorderCalled)
        XCTAssertEqual(flightRecorder.enableFlightRecorderDuration, .twentyFourHours)
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.loggingDurationChanged(:)` updates the state's logging duration value.
    @MainActor
    func test_receive_loggingDurationChanged() async throws {
        subject.receive(.loggingDurationChanged(.oneHour))
        XCTAssertEqual(subject.state.loggingDuration, .oneHour)

        subject.receive(.loggingDurationChanged(.eightHours))
        XCTAssertEqual(subject.state.loggingDuration, .eightHours)
    }
}
