// swiftlint:disable:this file_name
import BitwardenKitMocks
import BitwardenResources
import TestHelpers
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

    // MARK: Tests

    /// Tapping the close toolbar button dispatches the `.dismiss` action.
    @MainActor
    func test_close_tap() throws {
        let button = try subject.inspect().findCloseToolbarButton()
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
}
