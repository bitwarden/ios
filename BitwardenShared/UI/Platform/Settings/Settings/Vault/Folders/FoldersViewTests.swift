import SnapshotTesting
import XCTest

@testable import BitwardenShared

class FoldersViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<FoldersState, FoldersAction, FoldersEffect>!
    var subject: FoldersView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: FoldersState())
        let store = Store(processor: processor)

        subject = FoldersView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the add button dispatches the `.add` action.
    @MainActor
    func test_addButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.add)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .add)
    }

    /// Tapping on a folder button dispatches the `.folderTapped(id:)` action.
    @MainActor
    func test_folderButton_tap() throws {
        processor.state.folders = [.fixture(id: "test", name: "Secret Folder")]

        let button = try subject.inspect().find(button: "Secret Folder")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .folderTapped(id: "test"))
    }

    // MARK: Snapshots

    /// The empty view renders correctly.
    @MainActor
    func test_snapshot_empty() {
        processor.state.folders = []
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The folders view renders correctly.
    @MainActor
    func test_snapshot_folders() {
        processor.state.folders = [
            .fixture(id: "test", name: "Secret Folder"),
            .fixture(id: "test2", name: "Double Secret Folder"),
        ]
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
