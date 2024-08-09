import SnapshotTesting
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
    func test_cancelButton_tap() throws {
        var button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)

        // Again, with the edit form of the view.
        processor.state.mode = .edit(.fixture())
        button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the delete button performs the `.deleteTapped` effect.
    func test_deleteButton_tap() async throws {
        processor.state.mode = .edit(.fixture())

        let menu = try subject.inspect().find(ViewType.Menu.self, containing: Localizations.options)
        let button = try menu.find(asyncButton: Localizations.delete)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .deleteTapped)
    }

    /// Updating the text field dispatches the `.folderNameTextChanged()` action.
    func test_nameField_updateValue() throws {
        let textfield = try subject.inspect().find(viewWithId: Localizations.name).textField()
        try textfield.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .folderNameTextChanged("text"))
    }

    /// Tapping the save button performs the `.saveTapped` effect.
    func test_saveButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .saveTapped)
    }

    // MARK: Snapshots

    /// Tests the view renders correctly when the text field is empty.
    func test_snapshot_add_empty() {
        assertSnapshots(matching: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Tests the view renders correctly when the text field is populated.
    func test_snapshot_add_populated() {
        processor.state.folderName = "Super cool folder name"
        assertSnapshots(matching: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Tests the view renders correctly when the text field is populated.
    func test_snapshot_edit_populated() {
        processor.state.mode = .edit(.fixture())
        processor.state.folderName = "Super cool folder name"
        assertSnapshots(matching: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
