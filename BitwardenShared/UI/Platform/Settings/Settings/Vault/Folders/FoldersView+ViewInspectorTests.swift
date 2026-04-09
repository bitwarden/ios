// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

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

    /// Tapping the new folder floating action button dispatches the `.add` action.`
    @MainActor
    func test_addItemFloatingActionButton_tap() async throws {
        let fab = try subject.inspect().find(
            floatingActionButtonWithAccessibilityIdentifier: "AddItemFloatingActionButton",
        )
        try await fab.tap()
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
}
