import BitwardenSdk
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - VaultListViewTests

class VaultListViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultListState, VaultListAction, Void>!
    var subject: VaultListView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        let state = VaultListState(userInitials: "AA")
        processor = MockProcessor(state: state)
        subject = VaultListView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the add an item button dispatches the `.addItemPressed` action.
    func test_addItemButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.addAnItem)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed)
    }

    /// Tapping the profile button dispatches the `.profilePressed` action.
    func test_profileButton_tap() throws {
        let button = try subject.inspect().find(button: "AA")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .profilePressed)
    }

    func test_searchResult_tap() throws {
        let result = VaultListItem.fixture()
        processor.state.searchResults = [result]
        let button = try subject.inspect().find(button: "Example")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .itemPressed(item: result))
    }

    // MARK: Snapshots

    func test_snapshot_empty() {
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    func test_snapshot_withSearchResult() {
        processor.state.searchText = "Exam"
        processor.state.searchResults = [
            .fixture(),
        ]
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_withMultipleSearchResults() {
        processor.state.searchText = "Exam"
        processor.state.searchResults = [
            .fixture(cipherListView: .fixture(id: "1")),
            .fixture(cipherListView: .fixture(id: "2")),
            .fixture(cipherListView: .fixture(id: "3")),
            .fixture(cipherListView: .fixture(id: "4")),
        ]
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_withoutSearchResult() {
        processor.state.searchText = "Exam"
        processor.state.searchResults = []
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
