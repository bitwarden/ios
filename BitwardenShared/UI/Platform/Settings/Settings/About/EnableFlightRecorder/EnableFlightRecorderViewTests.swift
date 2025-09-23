import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class EnableFlightRecorderViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<EnableFlightRecorderState, EnableFlightRecorderAction, EnableFlightRecorderEffect>!
    var subject: EnableFlightRecorderView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: EnableFlightRecorderState())
        let store = Store(processor: processor)

        subject = EnableFlightRecorderView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel toolbar button dispatches the `.dismiss` action.
    @MainActor
    func test_cancel_tap() throws {
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Updating the value of the logging duration value sends the `.loggingDurationChanged` action.
    @MainActor
    func test_loggingDurationMenu_updateValue() throws {
        processor.state.loggingDuration = .twentyFourHours
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.loggingDuration)
        try menuField.select(newValue: FlightRecorderLoggingDuration.oneHour)
        XCTAssertEqual(processor.dispatchedActions.last, .loggingDurationChanged(.oneHour))
    }

    /// Tapping the save toolbar button performs the `.save` effect.
    @MainActor
    func test_save_tap() async throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-26079 Remove when toolbar AsyncButton is used.
            throw XCTSkip("Remove this when the toolbar save button gets updated to use AsyncButton.")
        }

        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .save)
    }

    // MARK: Snapshots

    /// The enable flight recorder view renders correctly.
    @MainActor
    func disabletest_snapshot_enableFlightRecorder() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 3)])
    }
}
