import BitwardenKitMocks
import BitwardenResources
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

    /// `receive(_:)` with `.delete` shows a confirmation alert and then deletes the specified log.
    @MainActor
    func test_receive_delete() async throws {
        let log = FlightRecorderLogMetadata.fixture()
        subject.receive(.delete(log))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .confirmDeleteLog(isBulkDeletion: false, action: {}))

        try await alert.tapAction(title: Localizations.cancel)
        XCTAssertTrue(flightRecorder.deleteLogLogs.isEmpty)

        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(flightRecorder.deleteLogLogs, [log])
        XCTAssertTrue(flightRecorder.fetchLogsCalled)
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.logDeleted))
    }

    /// `receive(_:)` with `.delete` logs an error and shows an error alert if an error occurs.
    @MainActor
    func test_receive_delete_error() async throws {
        flightRecorder.deleteLogResult = .failure(BitwardenTestError.example)

        subject.receive(.delete(.fixture()))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .confirmDeleteLog(isBulkDeletion: false, action: {}))

        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertNil(subject.state.toast)
    }

    /// `receive(_:)` with `.deleteAll` shows a confirmation alert and then deletes the inactive logs.
    @MainActor
    func test_receive_deleteAll() async throws {
        subject.receive(.deleteAll)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .confirmDeleteLog(isBulkDeletion: true, action: {}))

        try await alert.tapAction(title: Localizations.cancel)
        XCTAssertFalse(flightRecorder.deleteInactiveLogsCalled)

        try await alert.tapAction(title: Localizations.yes)

        XCTAssertTrue(flightRecorder.deleteInactiveLogsCalled)
        XCTAssertTrue(flightRecorder.fetchLogsCalled)
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.allLogsDeleted))
    }

    /// `receive(_:)` with `.deleteAll` logs an error and shows an error alert if an error occurs.
    @MainActor
    func test_receive_deleteAll_error() async throws {
        flightRecorder.deleteInactiveLogsResult = .failure(BitwardenTestError.example)

        subject.receive(.deleteAll)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .confirmDeleteLog(isBulkDeletion: true, action: {}))

        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertNil(subject.state.toast)
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.share` navigates to the share sheet for sharing a single log.
    @MainActor
    func test_receive_share() {
        let log = FlightRecorderLogMetadata.fixture()
        subject.receive(.share(log))
        XCTAssertEqual(coordinator.routes.last, .shareURL(log.url))
    }

    /// `receive(_:)` with `.shareAll` navigates to the share sheet for sharing multiple logs.
    @MainActor
    func test_receive_shareAll() {
        subject.state.logs = [
            .fixture(url: URL(fileURLWithPath: "/FlightRecorderLogs/1.txt")),
            .fixture(url: URL(fileURLWithPath: "/FlightRecorderLogs/2.txt")),
        ]

        subject.receive(.shareAll)

        XCTAssertEqual(
            coordinator.routes.last,
            .shareURLs([
                URL(fileURLWithPath: "/FlightRecorderLogs/1.txt"),
                URL(fileURLWithPath: "/FlightRecorderLogs/2.txt"),
            ])
        )
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    @MainActor
    func test_receive_toastShown() {
        let toast = Toast(title: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }
}
