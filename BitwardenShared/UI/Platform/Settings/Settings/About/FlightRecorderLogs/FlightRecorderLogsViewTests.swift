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
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2025, month: 4, day: 1)))
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
                duration: .eightHours,
                endDate: Date(year: 2025, month: 4, day: 1, hour: 8),
                fileSize: "2 KB",
                id: "1",
                isActiveLog: true,
                startDate: Date(year: 2025, month: 4, day: 1),
                url: URL(string: "https://example.com")!
            ),
            FlightRecorderLogMetadata(
                duration: .oneWeek,
                endDate: Date(year: 2025, month: 3, day: 7),
                fileSize: "12 KB",
                id: "2",
                isActiveLog: false,
                startDate: Date(year: 2025, month: 3, day: 7),
                url: URL(string: "https://example.com")!
            ),
            FlightRecorderLogMetadata(
                duration: .oneHour,
                endDate: Date(year: 2025, month: 3, day: 3, hour: 13),
                fileSize: "1.5 MB",
                id: "3",
                isActiveLog: false,
                startDate: Date(year: 2025, month: 3, day: 3, hour: 12),
                url: URL(string: "https://example.com")!
            ),
            FlightRecorderLogMetadata(
                duration: .twentyFourHours,
                endDate: Date(year: 2025, month: 3, day: 2),
                fileSize: "50 KB",
                id: "4",
                isActiveLog: false,
                startDate: Date(year: 2025, month: 3, day: 1),
                url: URL(string: "https://example.com")!
            ),
        ]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }
}
