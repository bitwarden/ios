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

    /// Test a snapshot of the ProfileSwitcherView previews.
    func test_snapshot_manualEntryView_previews() {
        for preview in ManualEntryView_Previews._allPreviews {
            assertSnapshots(
                matching: preview.content,
                as: [
                    .defaultPortrait,
                    .defaultLandscape,
                    .defaultPortraitAX5,
                ]
            )
        }
    }
}
