import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
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

    /// Tapping the delete log menu button dispatches the `.delete(_:)` action.
    @MainActor
    func test_delete_tap() throws {
        let log = FlightRecorderLogMetadata.fixture()
        processor.state.logs = [log]
        let button = try subject.inspect().find(button: Localizations.delete)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .delete(log))
    }

    /// The delete button is disabled for the active log.
    @MainActor
    func test_delete_disabledForActiveLog() throws {
        processor.state.logs = [.fixture(isActiveLog: true)]
        let button = try subject.inspect().find(button: Localizations.delete)
        XCTAssertTrue(button.isDisabled())
    }

    /// The delete all button is disabled when there's no logs or only an active log.
    @MainActor
    func test_deleteAll_disabledWhenNoLogs() throws {
        var button = try subject.inspect().find(button: Localizations.deleteAll)
        XCTAssertTrue(button.isDisabled())

        processor.state.logs = [.fixture(isActiveLog: true)]
        button = try subject.inspect().find(button: Localizations.deleteAll)
        XCTAssertTrue(button.isDisabled())

        processor.state.logs = [.fixture()]
        button = try subject.inspect().find(button: Localizations.deleteAll)
        XCTAssertFalse(button.isDisabled())
    }

    /// Tapping the delete all toolbar button dispatches the `.deleteAll` action.
    @MainActor
    func test_deleteAll_tap() throws {
        processor.state.logs = [.fixture()]
        let button = try subject.inspect().find(button: Localizations.deleteAll)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .deleteAll)
    }

    /// The share all button is disabled when there's no logs.
    @MainActor
    func test_shareAll_disabledWhenNoLogs() throws {
        var button = try subject.inspect().find(button: Localizations.shareAll)
        XCTAssertTrue(button.isDisabled())

        processor.state.logs = [.fixture()]
        button = try subject.inspect().find(button: Localizations.shareAll)
        XCTAssertFalse(button.isDisabled())
    }

    /// Tapping the share log menu button dispatches the `.share(_:)` action.
    @MainActor
    func test_share_tap() throws {
        let log = FlightRecorderLogMetadata.fixture()
        processor.state.logs = [log]
        let button = try subject.inspect().find(button: Localizations.share)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .share(log))
    }

    /// Tapping the share all toolbar button dispatches the `.shareAll` action.
    @MainActor
    func test_shareAll_tap() throws {
        processor.state.logs = [.fixture()]
        let button = try subject.inspect().find(button: Localizations.shareAll)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .shareAll)
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
                expirationDate: Date(year: 2025, month: 5, day: 1, hour: 8),
                fileSize: "2 KB",
                id: "1",
                isActiveLog: true,
                startDate: Date(year: 2025, month: 4, day: 1),
                url: URL(string: "https://example.com")!
            ),
            FlightRecorderLogMetadata(
                duration: .oneWeek,
                endDate: Date(year: 2025, month: 3, day: 7),
                expirationDate: Date(year: 2025, month: 4, day: 6),
                fileSize: "12 KB",
                id: "2",
                isActiveLog: false,
                startDate: Date(year: 2025, month: 3, day: 7),
                url: URL(string: "https://example.com")!
            ),
            FlightRecorderLogMetadata(
                duration: .oneHour,
                endDate: Date(year: 2025, month: 3, day: 3, hour: 13),
                expirationDate: Date(year: 2025, month: 4, day: 2, hour: 13),
                fileSize: "1.5 MB",
                id: "3",
                isActiveLog: false,
                startDate: Date(year: 2025, month: 3, day: 3, hour: 12),
                url: URL(string: "https://example.com")!
            ),
            FlightRecorderLogMetadata(
                duration: .twentyFourHours,
                endDate: Date(year: 2025, month: 3, day: 2),
                expirationDate: Date(year: 2025, month: 4, day: 1),
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
