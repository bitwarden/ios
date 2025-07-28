import BitwardenResources
import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - ManualEntryViewTests

class ManualEntryViewTests: BitwardenTestCase {
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

    /// Tapping the cancel button dispatches the `.dismiss` action.
    @MainActor
    func test_closeButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping the scan code button dispatches the `.scanCodePressed` action.
    @MainActor
    func test_scanCodeButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.scanQRCode)
        try button.tap()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .scanCodePressed)
    }

    /// Tapping the save button dispatches the `.addPressed(:)` action.
    @MainActor
    func test_saveButton_tap_empty() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addPressed(code: ""))
    }

    /// Tapping the save button dispatches the `.addPressed(:)` action.
    @MainActor
    func test_saveButton_tap_new() async throws {
        processor.state.authenticatorKey = "pasta-batman"
        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addPressed(code: "pasta-batman"))
    }

    // MARK: Snapshots

    /// Test a snapshot of the ProfileSwitcherView empty state.
    func test_snapshot_manualEntryView_empty() {
        assertSnapshots(
            of: ManualEntryView_Previews.empty,
            as: [
                .defaultPortrait,
                .defaultLandscape,
                .defaultPortraitDark,
            ]
        )
    }

    /// Test a snapshot of the ProfileSwitcherView in with text added.
    func test_snapshot_manualEntryView_text() {
        assertSnapshots(
            of: ManualEntryView_Previews.textAdded,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(heightMultiple: 1.75),
            ]
        )
    }
}
