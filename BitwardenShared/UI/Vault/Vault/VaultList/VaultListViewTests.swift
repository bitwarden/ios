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

        let account = ProfileSwitcherItem(
            email: "anne.account@bitwarden.com",
            userInitials: "AA"
        )
        let state = VaultListState(
            profileSwitcherState: ProfileSwitcherState(
                accounts: [account],
                activeAccountId: account.userId,
                isVisible: false
            )
        )
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
        processor.state.loadingState = .data([])
        let button = try subject.inspect().find(button: Localizations.add)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed)
    }

    /// Tapping a profile row dispatches the `.accountPressed` action.
    func test_accountRow_tap_currentAccount() throws {
        processor.state.profileSwitcherState.isVisible = true
        let accountRow = try subject.inspect().find(button: "anne.account@bitwarden.com")
        let currentAccount = processor.state.profileSwitcherState.activeAccountProfile!
        try accountRow.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .profileSwitcherAction(.accountPressed(currentAccount)))
    }

    /// Tapping the add account row dispatches the `.addAccountPressed ` action.
    func test_accountRow_tap_addAccount() throws {
        processor.state.profileSwitcherState.isVisible = true
        let addAccountRow = try subject.inspect().find(button: "Add account")
        try addAccountRow.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .profileSwitcherAction(.addAccountPressed))
    }

    /// Tapping the profile button dispatches the `.toggleProfilesViewVisibility` action.
    func test_profileButton_tap_withProfilesViewNotVisible() throws {
        processor.state.profileSwitcherState.isVisible = false
        let buttonUnselected = try subject.inspect().find(button: "AA")
        try buttonUnselected.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .profileSwitcherAction(.requestedProfileSwitcher(visible: true))
        )
    }

    /// Tapping the profile button dispatches the `.toggleProfilesViewVisibility` action.
    func test_profileButton_tap_withProfilesViewVisible() throws {
        processor.state.profileSwitcherState.isVisible = true
        let buttonUnselected = try subject.inspect().find(button: "AA")
        try buttonUnselected.tap()

        XCTAssertEqual(
            processor.dispatchedActions.last,
            .profileSwitcherAction(.requestedProfileSwitcher(visible: false))
        )
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
        processor.state.loadingState = .data([VaultListSection(id: "1", items: [item], name: "Group")])
        let button = try subject.inspect().find(button: Localizations.typeLogin)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .itemPressed(item: item))
    }

    func test_vaultItemMoreButton_tap() throws {
        let item = VaultListItem.fixture()
        processor.state.loadingState = .data([VaultListSection(id: "1", items: [item], name: "Group")])
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.more)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .morePressed(item: item))
    }

    // MARK: Snapshots

    func test_snapshot_empty() {
        processor.state.profileSwitcherState.isVisible = false
        processor.state.loadingState = .data([])

        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    func test_snapshot_empty_singleAccountProfileSwitcher() {
        processor.state.profileSwitcherState.isVisible = true
        processor.state.loadingState = .data([])

        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    func test_snapshot_loading() {
        processor.state.loadingState = .loading
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_myVault() {
        processor.state.loadingState = .data([
            VaultListSection(
                id: "",
                items: [
                    .fixture(),
                    .fixture(cipherListView: .fixture(id: "12", subTitle: "", type: .secureNote)),
                    .fixture(cipherListView: .fixture(
                        id: "13",
                        organizationId: "1",
                        name: "Bitwarden",
                        subTitle: "user@bitwarden.com"
                    )),
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
        ])
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
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

    /// Test a snapshot of the VaultListView previews.
    func test_snapshot_vaultListView_previews() {
        for preview in VaultListView_Previews._allPreviews {
            assertSnapshots(
                matching: preview.content,
                as: [.defaultPortrait]
            )
        }
    }
}
