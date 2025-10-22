// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import AuthenticatorShared

class ImportItemsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ImportItemsState, ImportItemsAction, ImportItemsEffect>!
    var subject: ImportItemsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ImportItemsState())
        let store = Store(processor: processor)

        subject = ImportItemsView(store: store)
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
        var button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the import items button sends the `.importItemsTapped` action.
    @MainActor
    func test_importItemsButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.importItems)
        try button.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .importItemsTapped)
    }

    /// Updating the value of the file format sends the  `.fileFormatTypeChanged()` action.
    @MainActor
    func test_fileFormatMenu_updateValue() throws {
        processor.state.fileFormat = .bitwardenJson
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.fileFormat)
        try menuField.select(newValue: ImportFormatType.bitwardenJson)
        XCTAssertEqual(processor.dispatchedActions.last, .fileFormatTypeChanged(.bitwardenJson))
    }
}
