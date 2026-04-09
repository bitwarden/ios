// swiftlint:disable:this file_name
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenKit

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

    // MARK: Snapshots

    /// The empty flight recorder logs view renders correctly.
    @MainActor
    func disabletest_snapshot_flightRecorderLogs_empty() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// The populated flight recorder logs view renders correctly.
    @MainActor
    func disabletest_snapshot_flightRecorderLogs_populated() {
        processor.state.logs = [
            FlightRecorderLogMetadata(
                duration: .eightHours,
                endDate: Date(year: 2025, month: 4, day: 1, hour: 8),
                expirationDate: Date(year: 2025, month: 5, day: 1, hour: 8),
                fileSize: "2 KB",
                id: "1",
                isActiveLog: true,
                startDate: Date(year: 2025, month: 4, day: 1),
                url: URL(string: "https://example.com")!,
            ),
            FlightRecorderLogMetadata(
                duration: .oneWeek,
                endDate: Date(year: 2025, month: 3, day: 7),
                expirationDate: Date(year: 2025, month: 4, day: 6),
                fileSize: "12 KB",
                id: "2",
                isActiveLog: false,
                startDate: Date(year: 2025, month: 3, day: 7),
                url: URL(string: "https://example.com")!,
            ),
            FlightRecorderLogMetadata(
                duration: .oneHour,
                endDate: Date(year: 2025, month: 3, day: 3, hour: 13),
                expirationDate: Date(year: 2025, month: 4, day: 2, hour: 13),
                fileSize: "1.5 MB",
                id: "3",
                isActiveLog: false,
                startDate: Date(year: 2025, month: 3, day: 3, hour: 12),
                url: URL(string: "https://example.com")!,
            ),
            FlightRecorderLogMetadata(
                duration: .twentyFourHours,
                endDate: Date(year: 2025, month: 3, day: 2),
                expirationDate: Date(year: 2025, month: 4, day: 1),
                fileSize: "50 KB",
                id: "4",
                isActiveLog: false,
                startDate: Date(year: 2025, month: 3, day: 1),
                url: URL(string: "https://example.com")!,
            ),
        ]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
