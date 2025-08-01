import BitwardenResources
import SnapshotTesting
import XCTest

@testable import AuthenticatorShared

class ExportItemsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ExportItemsState, ExportItemsAction, ExportItemsEffect>!
    var subject: ExportItemsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ExportItemsState())
        let store = Store(processor: processor)

        subject = ExportItemsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button dispatches the `.dismiss` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the export items button sends the `.exportItemsTapped` action.
    @MainActor
    func test_exportItemsButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.exportItems)
        try button.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .exportItemsTapped)
    }

    /// Updating the value of the file format sends the  `.fileFormatTypeChanged()` action.
    @MainActor
    func test_fileFormatMenu_updateValue() throws {
        processor.state.fileFormat = .json
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.fileFormat)
        try menuField.select(newValue: ExportFormatType.csv)
        XCTAssertEqual(processor.dispatchedActions.last, .fileFormatTypeChanged(.csv))
    }

    // MARK: Snapshots

    /// The empty view renders correctly.
    func test_snapshot_empty() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
