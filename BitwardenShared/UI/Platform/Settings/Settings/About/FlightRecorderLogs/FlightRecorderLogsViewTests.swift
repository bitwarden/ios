import SnapshotTesting
import XCTest

@testable import BitwardenShared

class FlightRecorderLogsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<FlightRecorderLogsState, FlightRecorderLogsAction, FlightRecorderLogsEffect>!
    var subject: FlightRecorderLogsView!
    var timeProvider: TimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: FlightRecorderLogsState())
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2025, month: 4, day: 4)))
        let store = Store(processor: processor)

        subject = FlightRecorderLogsView(store: store, timeProvider: timeProvider)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// Tapping the close toolbar button dispatches the `.dismiss` action.
    @MainActor
    func test_close_tap() throws {
        let button = try subject.inspect().find(button: Localizations.close)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    // MARK: Snapshots

    /// The empty flight recorder logs view renders correctly.
    @MainActor
    func test_snapshot_flightRecorderLogs_empty() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The populated flight recorder logs view renders correctly.
    @MainActor
    func test_snapshot_flightRecorderLogs_populated() {
        processor.state.logs = [
            FlightRecorderLogMetadata(
                duration: .oneHour,
                fileSize: "12 KB",
                id: "1",
                startDate: Date(year: 2025, month: 3, day: 4, hour: 8)
            ),
            FlightRecorderLogMetadata(
                duration: .eightHours,
                fileSize: "200 KB",
                id: "2",
                startDate: Date(year: 2025, month: 3, day: 20)
            ),
            FlightRecorderLogMetadata(
                duration: .oneWeek,
                fileSize: "347 KB",
                id: "3",
                startDate: Date(year: 2025, month: 4, day: 1, hour: 20)
            ),
        ]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }
}
