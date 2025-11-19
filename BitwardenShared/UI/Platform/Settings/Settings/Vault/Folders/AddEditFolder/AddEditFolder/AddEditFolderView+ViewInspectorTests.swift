// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import ViewInspector
import XCTest

@testable import BitwardenShared

class AddEditFolderViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AddEditFolderState, AddEditFolderAction, AddEditFolderEffect>!
    var subject: AddEditFolderView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AddEditFolderState(mode: .add))
        let store = Store(processor: processor)

        subject = AddEditFolderView(store: store)
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

        // Again, with the edit form of the view.
        processor.state.mode = .edit(.fixture())
        button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the delete button performs the `.deleteTapped` effect.
    @MainActor
    func test_deleteButton_tap() async throws {
        processor.state.mode = .edit(.fixture())

        let menu = try subject.inspect().find(ViewType.Menu.self, containing: Localizations.options)
        let button = try menu.find(asyncButton: Localizations.delete)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .deleteTapped)
    }

    /// Updating the text field dispatches the `.folderNameTextChanged()` action.
    @MainActor
    func test_nameField_updateValue() throws {
        let textfield = try subject.inspect().find(viewWithId: Localizations.name).textField()
        try textfield.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .folderNameTextChanged("text"))
    }

    /// Tapping the save button in add mode performs the `.saveTapped` effect.
    @MainActor
    func test_saveButton_tapAdd() async throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-26079 Remove when toolbar AsyncButton is used.
            throw XCTSkip("Remove this when the toolbar save button gets updated to use AsyncButton.")
        }

        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .saveTapped)
    }

    /// Tapping the save button in edit mode performs the `.saveTapped` effect.
    @MainActor
    func test_saveButton_tapEdit() async throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-26079 Remove when toolbar AsyncButton is used.
            throw XCTSkip("Remove this when the toolbar save button gets updated to use AsyncButton.")
        }

        processor.state.mode = .edit(.fixture())
        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .saveTapped)
    }
}
