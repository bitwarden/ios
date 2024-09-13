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
    @MainActor
    func test_addItemButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.add)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addTapped(fromToolbar: true))
    }

    /// Tapping the add an item button dispatches the `.addTapped` action.
    @MainActor
    func test_addItemButton_tap_fido2CreationFlowEmptyView() throws {
        processor.state.isCreatingFido2Credential = true
        processor.state.vaultListSections = []
        processor.state.emptyViewButtonText = Localizations.savePasskeyAsNewLogin
        let button = try subject.inspect().find(button: Localizations.savePasskeyAsNewLogin)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addTapped(fromToolbar: false))
    }

    /// Tapping the cancel button dispatches the `.cancelTapped` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .cancelTapped)
    }

    // MARK: Snapshots

    /// The empty view renders correctly.
    @MainActor
    func test_snapshot_vaultAutofillList_empty() {
        let account = ProfileSwitcherItem.anneAccount
        processor.state.profileSwitcherState.accounts = [account]
        processor.state.profileSwitcherState.activeAccountId = account.userId
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The empty view renders correctly when creating Fido2 credential.
    @MainActor
    func test_snapshot_vaultAutofillList_emptyFido2Creation() {
        let account = ProfileSwitcherItem.anneAccount
        processor.state.profileSwitcherState.accounts = [account]
        processor.state.profileSwitcherState.activeAccountId = account.userId
        processor.state.isCreatingFido2Credential = true
        processor.state.emptyViewMessage = Localizations.noItemsForUri("myApp.com")
        processor.state.emptyViewButtonText = Localizations.savePasskeyAsNewLogin
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The populated view renders correctly.
    @MainActor
    func test_snapshot_vaultAutofillList_populated() {
        let account = ProfileSwitcherItem.anneAccount
        processor.state.profileSwitcherState.accounts = [account]
        processor.state.profileSwitcherState.activeAccountId = account.userId
        processor.state.vaultListSections = [
            VaultListSection(
                id: "",
                items: [
                    .init(
                        cipherView: .fixture(
                            id: "1",
                            login: .fixture(
                                username: "user@bitwarden.com"
                            ),
                            name: "Apple"
                        )
                    )!,
                    .init(
                        cipherView: .fixture(
                            id: "2",
                            login: .fixture(
                                username: "user@bitwarden.com"
                            ),
                            name: "Bitwarden"
                        )
                    )!,
                    .init(
                        cipherView: .fixture(
                            id: "3",
                            login: .fixture(
                                username: ""
                            ),
                            name: "Company XYZ"
                        )
                    )!,
                ],
                name: ""
            ),
        ]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The populated view renders correctly when mixing passwords and Fido2 credentials on Fido2 creation context.
    @MainActor
    func test_snapshot_vaultAutofillList_fido2Creation() { // swiftlint:disable:this function_body_length
        let account = ProfileSwitcherItem.anneAccount
        processor.state.profileSwitcherState.accounts = [account]
        processor.state.profileSwitcherState.activeAccountId = account.userId
        processor.state.isCreatingFido2Credential = true
        processor.state.vaultListSections = [
            VaultListSection(
                id: Localizations.chooseALoginToSaveThisPasskeyTo,
                items: [
                    .init(
                        cipherView: .fixture(
                            id: "1",
                            login: .fixture(
                                username: "user@bitwarden.com"
                            ),
                            name: "Apple"
                        )
                    )!,
                    .init(
                        cipherView: .fixture(
                            id: "2",
                            login: .fixture(
                                username: "user@bitwarden.com"
                            ),
                            name: "Bitwarden"
                        )
                    )!,
                    .init(
                        cipherView: .fixture(
                            id: "3",
                            login: .fixture(
                                username: ""
                            ),
                            name: "Company XYZ"
                        )
                    )!,
                    .init(
                        cipherView: .fixture(
                            id: "4",
                            login: .fixture(
                                username: ""
                            ),
                            name: "App"
                        ),
                        fido2CredentialAutofillView: .fixture(
                            userNameForUi: "myFido2Username"
                        )
                    )!,
                    .init(
                        cipherView: .fixture(
                            id: "5",
                            login: .fixture(
                                username: ""
                            ),
                            name: "myApp.com"
                        ),
                        fido2CredentialAutofillView: .fixture(
                            userNameForUi: "another user"
                        )
                    )!,
                ],
                name: Localizations.chooseALoginToSaveThisPasskeyTo
            ),
        ]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The populated view renders correctly when mixing passwords and Fido2 credentials on multiple sections.
//    @MainActor
//    func test_snapshot_vaultAutofillList_populatedWithFido2_multipleSections() { // swiftlint:disable:this function_body_length
//        // swiftlint:disable:previous line_length
//        let account = ProfileSwitcherItem.anneAccount
//        processor.state.profileSwitcherState.accounts = [account]
//        processor.state.profileSwitcherState.activeAccountId = account.userId
//        processor.state.isAutofillingFido2List = true
//        processor.state.vaultListSections = [
//            VaultListSection(
//                id: "Passkeys for myApp.com",
//                items: [
//                    .init(
//                        cipherView: .fixture(
//                            id: "4",
//                            login: .fixture(
//                                username: ""
//                            ),
//                            name: "App"
//                        ),
//                        fido2CredentialAutofillView: .fixture(
//                            userNameForUi: "myFido2Username"
//                        )
//                    )!,
//                    .init(
//                        cipherView: .fixture(
//                            id: "5",
//                            login: .fixture(
//                                username: ""
//                            ),
//                            name: "myApp.com"
//                        ),
//                        fido2CredentialAutofillView: .fixture(
//                            userNameForUi: "another user"
//                        )
//                    )!,
//                ],
//                name: "Passkeys for myApp.com"
//            ),
//            VaultListSection(
//                id: "Passwords for myApp.com",
//                items: [
//                    .init(
//                        cipherView: .fixture(
//                            id: "1",
//                            login: .fixture(
//                                username: "user@bitwarden.com"
//                            ),
//                            name: "Apple"
//                        )
//                    )!,
//                    .init(
//                        cipherView: .fixture(
//                            id: "2",
//                            login: .fixture(
//                                username: "user@bitwarden.com"
//                            ),
//                            name: "Bitwarden"
//                        )
//                    )!,
//                    .init(
//                        cipherView: .fixture(
//                            id: "3",
//                            login: .fixture(
//                                username: ""
//                            ),
//                            name: "Company XYZ"
//                        )
//                    )!,
//                ],
//                name: "Passwords for myApp.com"
//            ),
//        ]
//        assertSnapshots(
//            of: subject.navStackWrapped,
//            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
//        )
//    }
}
