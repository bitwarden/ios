import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class EditCollectionsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<EditCollectionsState, EditCollectionsAction, EditCollectionsEffect>!
    var subject: EditCollectionsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: EditCollectionsState(cipher: .fixture()))
        let store = Store(processor: processor)

        subject = EditCollectionsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button dispatches the `.dismissPressed` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping the save button dispatches the `.save` action.
    @MainActor
    func test_saveButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .save)
    }

    // MARK: Previews

    /// The edit collections view renders correctly.
    @MainActor
    func test_snapshot_editCollections() {
        processor.state.collections = [
            .fixture(id: "1", name: "Design", organizationId: "1"),
            .fixture(id: "2", name: "Engineering", organizationId: "1"),
        ]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }
}
