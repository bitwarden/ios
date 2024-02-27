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
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        let account = ProfileSwitcherItem.fixture(
            email: "anne.account@bitwarden.com",
            userInitials: "AA"
        )
        let state = VaultListState(
            profileSwitcherState: ProfileSwitcherState(
                accounts: [account],
                activeAccountId: account.userId,
                allowLockAndLogout: true,
                isVisible: false
            )
        )
        processor = MockProcessor(state: state)
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2023, month: 12, day: 31)))
        subject = VaultListView(
            store: Store(processor: processor),
            timeProvider: timeProvider
        )
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// Tapping the add item button dispatches the `.addItemPressed` action.
    func test_addItemButton_tap() throws {
        processor.state.loadingState = .data([])
        let button = try subject.inspect().find(button: Localizations.add)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed)
    }

    /// Tapping the add an item button dispatches the `.addItemPressed` action.
    func test_addAnItemButton_tap() throws {
        processor.state.loadingState = .data([])
        let button = try subject.inspect().find(button: Localizations.addAnItem)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed)
    }

    /// Long pressing a profile row dispatches the `.accountLongPressed` action.
    func test_accountRow_longPress_currentAccount() throws {
        processor.state.profileSwitcherState.isVisible = true
        let accountRow = try subject.inspect().find(button: "anne.account@bitwarden.com")
        let currentAccount = processor.state.profileSwitcherState.activeAccountProfile!
        try accountRow.labelView().callOnLongPressGesture()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .profileSwitcher(.accountLongPressed(currentAccount)))
    }

    /// Tapping a profile row dispatches the `.accountPressed` action.
    func test_accountRow_tap_currentAccount() throws {
        processor.state.profileSwitcherState.isVisible = true
        let accountRow = try subject.inspect().find(button: "anne.account@bitwarden.com")
        let currentAccount = processor.state.profileSwitcherState.activeAccountProfile!
        try accountRow.labelView().callOnTapGesture()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .profileSwitcher(.accountPressed(currentAccount)))
    }

    /// Tapping the add account row dispatches the `.addAccountPressed ` action.
    func test_accountRow_tap_addAccount() throws {
        processor.state.profileSwitcherState.isVisible = true
        let addAccountRow = try subject.inspect().find(button: "Add account")
        try addAccountRow.tap()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .profileSwitcher(.addAccountPressed))
    }

    /// Tapping the profile button dispatches the `.toggleProfilesViewVisibility` action.
    func test_profileButton_tap_withProfilesViewNotVisible() throws {
        processor.state.profileSwitcherState.isVisible = false
        let buttonUnselected = try subject.inspect().find(button: "AA")
        try buttonUnselected.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .profileSwitcher(.requestedProfileSwitcher(visible: true))
        )
    }

    /// Tapping the profile button dispatches the `.toggleProfilesViewVisibility` action.
    func test_profileButton_tap_withProfilesViewVisible() throws {
        processor.state.profileSwitcherState.isVisible = true
        let buttonUnselected = try subject.inspect().find(button: "AA")
        try buttonUnselected.tap()

        XCTAssertEqual(
            processor.dispatchedActions.last,
            .profileSwitcher(.requestedProfileSwitcher(visible: false))
        )
    }

    /// Tapping the search result dispatches the `.itemPressed` action.
    func test_searchResult_tap() throws {
        let result = VaultListItem.fixture()
        processor.state.searchResults = [result]
        let button = try subject.inspect().find(button: "Bitwarden")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .itemPressed(item: result))
    }

    /// Tapping the vault item dispatches the `.itemPressed` action.
    func test_vaultItem_tap() throws {
        let item = VaultListItem(id: "1", itemType: .group(.login, 123))
        processor.state.loadingState = .data([VaultListSection(id: "1", items: [item], name: "Group")])
        let button = try subject.inspect().find(button: Localizations.typeLogin)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .itemPressed(item: item))
    }

    /// Tapping the vault item copy totp button dispatches the `.copyTOTPCode` action.
    func test_vaultItem_copyTOTPButton_tap() throws {
        let item = VaultListItem.fixtureTOTP(totp: .fixture())
        processor.state.loadingState = .data([VaultListSection(id: "1", items: [item], name: "Group")])
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copyTotp)
        try button.tap()
        waitFor(!processor.dispatchedActions.isEmpty)
        XCTAssertEqual(processor.dispatchedActions.last, .copyTOTPCode("123456"))
    }

    /// Tapping the vault item more button dispatches the `.morePressed` action.
    func test_vaultItem_moreButton_tap() throws {
        let item = VaultListItem.fixture()
        processor.state.loadingState = .data([VaultListSection(id: "1", items: [item], name: "Group")])
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.more)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .morePressed(item))
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
        processor.state.loadingState = .loading(nil)
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_myVault() {
        processor.state.loadingState = .data([
            VaultListSection(
                id: "",
                items: [
                    .fixture(cipherView: .fixture(
                        login: .fixture(username: "email@example.com"),
                        name: "Example"
                    )),
                    .fixture(cipherView: .fixture(id: "12", name: "Example", type: .secureNote)),
                    .fixture(cipherView: .loginFixture(
                        attachments: [.fixture()],
                        id: "13",
                        login: .fixture(username: "user@bitwarden.com"),
                        name: "Bitwarden",
                        organizationId: "1"
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
            .fixture(cipherView: .fixture(
                login: .fixture(username: "email@example.com"),
                name: "Example"
            )),
        ]
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_withMultipleSearchResults() {
        processor.state.searchText = "Exam"
        processor.state.searchResults = [
            .fixture(cipherView: .fixture(
                id: "1",
                login: .fixture(username: "email@example.com"),
                name: "Example"
            )),
            .fixture(cipherView: .fixture(
                id: "2",
                login: .fixture(username: "email@example.com"),
                name: "Example"
            )),
            .fixture(cipherView: .fixture(
                id: "3",
                login: .fixture(username: "email@example.com"),
                name: "Example"
            )),
            .fixture(cipherView: .fixture(
                id: "4",
                login: .fixture(username: "email@example.com"),
                name: "Example"
            )),
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
