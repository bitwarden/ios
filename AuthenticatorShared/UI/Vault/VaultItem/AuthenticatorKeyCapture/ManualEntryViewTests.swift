import BitwardenResources
import SnapshotTesting
import ViewInspector
import XCTest

@testable import AuthenticatorShared

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

    /// Tapping the add local code button dispatches the `.addPressed(:)` action.
    @MainActor
    func test_addButton_tap_empty() throws {
        let button = try subject.inspect().find(button: Localizations.addCode)
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .addPressed(code: "", name: "", sendToBitwarden: false)
        )
    }

    /// Tapping the add local code button dispatches the `.addPressed(:)` action.
    @MainActor
    func test_addButton_tap_new() throws {
        processor.state.name = "wayne"
        processor.state.authenticatorKey = "pasta-batman"
        let button = try subject.inspect().find(button: Localizations.addCode)
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .addPressed(code: "pasta-batman", name: "wayne", sendToBitwarden: false)
        )
    }

    /// Tapping the Save here button dispatches the `.addPressed(:)` action.
    @MainActor
    func test_addLocallyButton_tap_empty() throws {
        processor.state.isPasswordManagerSyncActive = true
        let button = try subject.inspect().find(button: Localizations.saveHere)
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .addPressed(code: "", name: "", sendToBitwarden: false)
        )
    }

    /// Tapping the Save here button dispatches the `.addPressed(:)` action.
    @MainActor
    func test_addLocallyButton_tap_textEntered() throws {
        processor.state.name = "wayne"
        processor.state.authenticatorKey = "pasta-batman"
        processor.state.isPasswordManagerSyncActive = true
        let button = try subject.inspect().find(button: Localizations.saveHere)
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .addPressed(code: "pasta-batman", name: "wayne", sendToBitwarden: false)
        )
    }

    /// Tapping the add to Bitwarden button dispatches the `.addPressed(:)` action.
    @MainActor
    func test_addToBitwardenButton_tap_empty() throws {
        processor.state.isPasswordManagerSyncActive = true
        let button = try subject.inspect().find(button: Localizations.saveToBitwarden)
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .addPressed(code: "", name: "", sendToBitwarden: true)
        )
    }

    /// Tapping the add to Bitwarden button dispatches the `.addPressed(:)` action.
    @MainActor
    func test_addToBitwardenButton_tap_textEntered() throws {
        processor.state.name = "wayne"
        processor.state.authenticatorKey = "pasta-batman"
        processor.state.isPasswordManagerSyncActive = true
        let button = try subject.inspect().find(button: Localizations.saveToBitwarden)
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .addPressed(code: "pasta-batman", name: "wayne", sendToBitwarden: true)
        )
    }

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
        let button = try subject.inspect().find(
            button: Localizations.cannotAddAuthenticatorKey + " " + Localizations.scanQRCode
        )
        try button.tap()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .scanCodePressed)
    }

    // MARK: Snapshots

    /// Test a snapshot of the `ManualEntryView` empty state.
    func test_snapshot_manualEntryView_empty() {
        assertSnapshot(
            of: ManualEntryView_Previews.empty,
            as: .defaultPortrait
        )
    }

    /// Test a snapshot of the `ManualEntryView` empty state.
    func test_snapshot_manualEntryView_empty_landscape() {
        assertSnapshot(
            of: ManualEntryView_Previews.empty,
            as: .defaultLandscape
        )
    }

    /// Test a snapshot of the `ManualEntryView` in dark mode.
    func test_snapshot_manualEntryView_text_dark() {
        assertSnapshot(
            of: ManualEntryView_Previews.textAdded,
            as: .defaultPortraitDark
        )
    }

    /// Test a snapshot of the `ManualEntryView` with large text.
    func test_snapshot_manualEntryView_text_largeText() {
        assertSnapshot(
            of: ManualEntryView_Previews.textAdded,
            as: .tallPortraitAX5(heightMultiple: 1.75)
        )
    }

    /// Test a snapshot of the `ManualEntryView` in light mode.
    func test_snapshot_manualEntryView_text_light() {
        assertSnapshot(
            of: ManualEntryView_Previews.textAdded,
            as: .defaultPortrait
        )
    }

    /// Test a snapshot of the `ManualEntryView` in dark mode with the
    /// password manager sync flag active.
    func test_snapshot_manualEntryView_text_dark_syncActive() {
        assertSnapshot(
            of: ManualEntryView_Previews.syncActiveNoDefault,
            as: .defaultPortraitDark
        )
    }

    /// Test a snapshot of the `ManualEntryView` with large text with the
    /// password manager sync flag active.
    func test_snapshot_manualEntryView_text_largeText_syncActive() {
        assertSnapshot(
            of: ManualEntryView_Previews.syncActiveNoDefault,
            as: .tallPortraitAX5(heightMultiple: 1.75)
        )
    }

    /// Test a snapshot of the `ManualEntryView` in light mode with the
    /// password manager sync flag active.
    func test_snapshot_manualEntryView_text_light_syncActive() {
        assertSnapshot(
            of: ManualEntryView_Previews.syncActiveNoDefault,
            as: .defaultPortrait
        )
    }

    /// Test a snapshot of the `ManualEntryView` previews.
    func test_snapshot_manualEntryView_previews() {
        for preview in ManualEntryView_Previews._allPreviews {
            let name = preview.displayName ?? "Unknown"
            assertSnapshots(
                of: preview.content,
                as: [
                    "\(name)-portrait": .defaultPortrait,
                    "\(name)-portraitDark": .defaultPortraitDark,
                    "\(name)-portraitAX5": .defaultPortraitAX5,
                ]
            )
        }
    }
}
