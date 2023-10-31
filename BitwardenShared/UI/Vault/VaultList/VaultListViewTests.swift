import BitwardenSdk
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - VaultListViewTests

class VaultListViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultListState, VaultListAction, VaultListEffect>!
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

    func test_vaultItem_tap() throws {
        let item = VaultListItem(id: "1", itemType: .group(.login, 123))
        processor.state.sections = [VaultListSection(id: "1", items: [item], name: "Group")]
        let button = try subject.inspect().find(button: Localizations.typeLogin)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .itemPressed(item: item))
    }

    func test_vaultItemMoreButton_tap() throws {
        let item = VaultListItem.fixture()
        processor.state.sections = [VaultListSection(id: "1", items: [item], name: "Group")]
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.more)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .morePressed(item: item))
    }

    // MARK: Snapshots

    func test_snapshot_empty() {
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    func test_snapshot_myVault() {
        processor.state.sections = [
            VaultListSection(
                id: "",
                items: [
                    .fixture(),
                ],
                name: "Favorites"
            ),
            VaultListSection(
                id: "2",
                items: [
                    VaultListItem(
                        id: "21",
                        itemType: .group(.login, 123)
                    ),
                    VaultListItem(
                        id: "22",
                        itemType: .group(.card, 25)
                    ),
                    VaultListItem(
                        id: "23",
                        itemType: .group(.identity, 1)
                    ),
                    VaultListItem(
                        id: "24",
                        itemType: .group(.secureNote, 0)
                    ),
                ],
                name: "Types"
            ),
        ]
        assertSnapshot(of: subject, as: .defaultPortrait)
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
