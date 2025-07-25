import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class SingleSignOnViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SingleSignOnState, SingleSignOnAction, SingleSignOnEffect>!
    var subject: SingleSignOnView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SingleSignOnState())
        let store = Store(processor: processor)

        subject = SingleSignOnView(store: store)
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

    /// Updating the text field dispatches the `.identifierTextChanged()` action.
    @MainActor
    func test_identifierField_updateValue() throws {
        let textfield = try subject.inspect().find(viewWithId: Localizations.orgIdentifier).textField()
        try textfield.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .identifierTextChanged("text"))
    }

    /// Tapping the login button performs the `.loginTapped` effect.
    @MainActor
    func test_saveButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.logIn)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .loginTapped)
    }

    // MARK: Snapshots

    /// Tests the view renders correctly when the text field is empty.
    func test_snapshot_empty() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// Tests the view renders correctly when the text field is populated.
    @MainActor
    func test_snapshot_populated() {
        processor.state.identifierText = "Insert cool identifier here"
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }
}
