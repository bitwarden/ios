import BitwardenSdk
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class VaultItemSelectionViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultItemSelectionState, VaultItemSelectionAction, VaultItemSelectionEffect>!
    var subject: VaultItemSelectionView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: VaultItemSelectionState(
            iconBaseURL: nil,
            otpAuthModel: .fixtureExample
        ))
        let store = Store(processor: processor)

        subject = VaultItemSelectionView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the add an item button dispatches the `.addTapped` action.
    func test_addItemButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.add)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addTapped)
    }

    /// Tapping the cancel button dispatches the `.cancelTapped` action.
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .cancelTapped)
    }

    /// In the empty state, tapping the add item button dispatches the `.addTapped` action.
    func test_emptyState_addItemTapped() throws {
        let button = try subject.inspect().find(button: Localizations.addAnItem)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addTapped)
    }

    // MARK: Snapshots

    /// The empty view renders correctly.
    func test_snapshot_cipherSelection_empty() {
        let account = ProfileSwitcherItem.anneAccount
        processor.state.profileSwitcherState.accounts = [account]
        processor.state.profileSwitcherState.activeAccountId = account.userId
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The populated view renders correctly.
    func test_snapshot_cipherSelection_populated() {
        let account = ProfileSwitcherItem.anneAccount
        processor.state.profileSwitcherState.accounts = [account]
        processor.state.profileSwitcherState.activeAccountId = account.userId
        let ciphers: [CipherView] = [
            .fixture(id: "1", login: .fixture(username: "user@bitwarden.com"), name: "Example"),
            .fixture(id: "2", login: .fixture(username: "user@bitwarden.com"), name: "Example Co"),
        ]
        processor.state.vaultListSections = [
            VaultListSection(
                id: Localizations.matchingItems,
                items: ciphers.compactMap(VaultListItem.init),
                name: Localizations.matchingItems
            ),
        ]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }
}
