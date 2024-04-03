import SnapshotTesting
import ViewInspector
import XCTest

@testable import AuthenticatorShared

// MARK: - ManualEntryViewTests

class ManualEntryViewTests: AuthenticatorTestCase {
    // MARK: Properties

    var processor: MockProcessor<ManualEntryState, ManualEntryAction, ManualEntryEffect>!
    var subject: ManualEntryView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: DefaultEntryState(deviceSupportsCamera: true))
        let store = Store(processor: processor)
        subject = ManualEntryView(
            store: store
        )
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the add button dispatches the `.addPressed(:)` action.
    func test_addButton_tap_empty() throws {
        let button = try subject.inspect().find(button: Localizations.addTotp)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addPressed(code: ""))
    }

    /// Tapping the add button dispatches the `.addPressed(:)` action.
    func test_addButton_tap_new() throws {
        processor.state.authenticatorKey = "pasta-batman"
        let button = try subject.inspect().find(button: Localizations.addTotp)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addPressed(code: "pasta-batman"))
    }

    /// Tapping the cancel button dispatches the `.dismiss` action.
    func test_closeButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping the scan code button dispatches the `.scanCodePressed` action.
    func test_scanCodeButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.scanQRCode)
        try button.tap()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .scanCodePressed)
    }

    // MARK: Snapshots

    /// Test a snapshot of the ProfileSwitcherView empty state.
    func test_snapshot_manualEntryView_empty() {
        assertSnapshot(
            matching: ManualEntryView_Previews.empty,
            as: .defaultPortrait
        )
    }

    /// Test a snapshot of the ProfileSwitcherView empty state.
    func test_snapshot_manualEntryView_empty_landscape() {
        assertSnapshot(
            matching: ManualEntryView_Previews.empty,
            as: .defaultLandscape
        )
    }

    /// Test a snapshot of the ProfileSwitcherView in dark mode.
    func test_snapshot_manualEntryView_text_dark() {
        assertSnapshot(
            matching: ManualEntryView_Previews.textAdded,
            as: .defaultPortraitDark
        )
    }

    /// Test a snapshot of the ProfileSwitcherView with large text.
    func test_snapshot_manualEntryView_text_largeText() {
        assertSnapshot(
            matching: ManualEntryView_Previews.textAdded,
            as: .tallPortraitAX5(heightMultiple: 1.75)
        )
    }

    /// Test a snapshot of the ProfileSwitcherView in light mode.
    func test_snapshot_manualEntryView_text_light() {
        assertSnapshot(
            matching: ManualEntryView_Previews.textAdded,
            as: .defaultPortrait
        )
    }
}
