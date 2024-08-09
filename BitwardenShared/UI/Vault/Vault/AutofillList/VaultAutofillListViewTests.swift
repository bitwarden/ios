import SnapshotTesting
import XCTest

@testable import BitwardenShared

class VaultAutofillListViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultAutofillListState, VaultAutofillListAction, VaultAutofillListEffect>!
    var subject: VaultAutofillListView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: VaultAutofillListState())
        let store = Store(processor: processor)

        subject = VaultAutofillListView(store: store)
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

    // MARK: Snapshots

    /// The empty view renders correctly.
    func test_snapshot_vaultAutofillList_empty() {
        let account = ProfileSwitcherItem.anneAccount
        processor.state.profileSwitcherState.accounts = [account]
        processor.state.profileSwitcherState.activeAccountId = account.userId
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The populated view renders correctly.
    func test_snapshot_vaultAutofillList_populated() {
        let account = ProfileSwitcherItem.anneAccount
        processor.state.profileSwitcherState.accounts = [account]
        processor.state.profileSwitcherState.activeAccountId = account.userId
        processor.state.ciphersForAutofill = [
            .init(cipherView: .fixture(id: "1", login: .fixture(username: "user@bitwarden.com"), name: "Apple"))!,
            .init(cipherView: .fixture(id: "2", login: .fixture(username: "user@bitwarden.com"), name: "Bitwarden"))!,
            .init(cipherView: .fixture(id: "3", login: .fixture(username: ""), name: "Company XYZ"))!,
        ]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The populated view renders correctly when mixing passwords and Fido2 credentials.
    func test_snapshot_vaultAutofillList_populatedWithFido2() {
        let account = ProfileSwitcherItem.anneAccount
        processor.state.profileSwitcherState.accounts = [account]
        processor.state.profileSwitcherState.activeAccountId = account.userId
        processor.state.ciphersForAutofill = [
            .init(cipherView: .fixture(id: "1", login: .fixture(username: "user@bitwarden.com"), name: "Apple"))!,
            .init(cipherView: .fixture(id: "2", login: .fixture(username: "user@bitwarden.com"), name: "Bitwarden"))!,
            .init(cipherView: .fixture(id: "3", login: .fixture(username: ""), name: "Company XYZ"))!,
            .init(cipherView: .fixture(
                id: "4",
                login: .fixture(
                    username: ""
                ),
                name: "App"
            ), fido2CredentialAutofillView: .fixture(userNameForUi: "myFido2Username"))!,
            .init(cipherView: .fixture(
                id: "5",
                login: .fixture(
                    username: ""
                ),
                name: "myApp.com"
            ), fido2CredentialAutofillView: .fixture(userNameForUi: "another user"))!,
        ]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }
}
