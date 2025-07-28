import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class VaultAutofillListViewTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var processor: MockProcessor<VaultAutofillListState, VaultAutofillListAction, VaultAutofillListEffect>!
    var subject: VaultAutofillListView!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: VaultAutofillListState())
        let store = Store(processor: processor)
        timeProvider = MockTimeProvider(.currentTime)

        subject = VaultAutofillListView(store: store, timeProvider: timeProvider)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// Tapping the add item floating action button dispatches the `.addItemPressed` action.`
    @MainActor
    func test_addItemFloatingActionButton_tap() async throws {
        let fab = try subject.inspect().find(
            floatingActionButtonWithAccessibilityIdentifier: "AddItemFloatingActionButton"
        )
        try await fab.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addTapped(fromFAB: true))
    }

    /// Tapping the add an item button dispatches the `.addTapped` action.
    @MainActor
    func test_addItemButton_tap_fido2CreationFlowEmptyView() throws {
        processor.state.isCreatingFido2Credential = true
        processor.state.vaultListSections = []
        processor.state.emptyViewButtonText = Localizations.savePasskeyAsNewLogin
        let button = try subject.inspect().find(button: Localizations.savePasskeyAsNewLogin)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addTapped(fromFAB: false))
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
                        cipherListView: .fixture(
                            id: "1",
                            login: .fixture(
                                username: "user@bitwarden.com"
                            ),
                            name: "Apple",
                            subtitle: "user@bitwarden.com"
                        )
                    )!,
                    .init(
                        cipherListView: .fixture(
                            id: "2",
                            login: .fixture(
                                username: "user@bitwarden.com"
                            ),
                            name: "Bitwarden",
                            subtitle: "user@bitwarden.com"
                        )
                    )!,
                    .init(
                        cipherListView: .fixture(
                            id: "3",
                            login: .fixture(
                                username: ""
                            ),
                            name: "Company XYZ",
                            subtitle: ""
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
                        cipherListView: .fixture(
                            id: "1",
                            login: .fixture(
                                username: "user@bitwarden.com"
                            ),
                            name: "Apple",
                            subtitle: "user@bitwarden.com"
                        )
                    )!,
                    .init(
                        cipherListView: .fixture(
                            id: "2",
                            login: .fixture(
                                username: "user@bitwarden.com"
                            ),
                            name: "Bitwarden",
                            subtitle: "user@bitwarden.com"
                        )
                    )!,
                    .init(
                        cipherListView: .fixture(
                            id: "3",
                            login: .fixture(
                                username: ""
                            ),
                            name: "Company XYZ"
                        )
                    )!,
                    .init(
                        cipherListView: .fixture(
                            id: "4",
                            login: .fixture(
                                username: ""
                            ),
                            name: "App",
                            subtitle: "myFido2Username"
                        ),
                        fido2CredentialAutofillView: .fixture(
                            userNameForUi: "myFido2Username"
                        )
                    )!,
                    .init(
                        cipherListView: .fixture(
                            id: "5",
                            login: .fixture(
                                username: ""
                            ),
                            name: "myApp.com",
                            subtitle: "another user"
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
    @MainActor
    func test_snapshot_vaultAutofillList_populatedWithFido2_multipleSections() { // swiftlint:disable:this function_body_length
        // swiftlint:disable:previous line_length
        let account = ProfileSwitcherItem.anneAccount
        processor.state.profileSwitcherState.accounts = [account]
        processor.state.profileSwitcherState.activeAccountId = account.userId
        processor.state.isAutofillingFido2List = true
        processor.state.vaultListSections = [
            VaultListSection(
                id: "Passkeys for myApp.com",
                items: [
                    .init(
                        cipherListView: .fixture(
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
                        cipherListView: .fixture(
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
                name: "Passkeys for myApp.com"
            ),
            VaultListSection(
                id: "Passwords for myApp.com",
                items: [
                    .init(
                        cipherListView: .fixture(
                            id: "1",
                            login: .fixture(
                                username: "user@bitwarden.com"
                            ),
                            name: "Apple"
                        )
                    )!,
                    .init(
                        cipherListView: .fixture(
                            id: "2",
                            login: .fixture(
                                username: "user@bitwarden.com"
                            ),
                            name: "Bitwarden"
                        )
                    )!,
                    .init(
                        cipherListView: .fixture(
                            id: "3",
                            login: .fixture(
                                username: ""
                            ),
                            name: "Company XYZ"
                        )
                    )!,
                ],
                name: "Passwords for myApp.com"
            ),
        ]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The populated view renders correctly when autofilling text to insert.
    @MainActor
    func test_snapshot_vaultAutofillList_populatedWhenAutofillingTextToInsert() {
        // swiftlint:disable:previous function_body_length

        let account = ProfileSwitcherItem.anneAccount
        processor.state.profileSwitcherState.accounts = [account]
        processor.state.profileSwitcherState.activeAccountId = account.userId
        processor.state.isAutofillingTextToInsertList = true
        processor.state.vaultListSections = [
            VaultListSection(
                id: "",
                items: [
                    .fixture(cipherListView: .fixture(
                        login: .fixture(
                            username: "email@example.com"
                        ),
                        name: "Example",
                        subtitle: "email@example.com"
                    )),
                    .fixture(cipherListView: .fixture(id: "12", name: "Example", type: .secureNote)),
                    .fixture(cipherListView: .fixture(
                        id: "13",
                        organizationId: "1",
                        login: .fixture(
                            username: "user@bitwarden.com"
                        ),
                        name: "Bitwarden",
                        subtitle: "user@bitwarden.com",
                        attachments: 1
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
        ]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The populated view renders correctly when autofilling text to insert when filtering by group.
    @MainActor
    func test_snapshot_vaultAutofillList_populatedWhenAutofillingTextToInsertWithGroup() {
        // swiftlint:disable:previous function_body_length
        let account = ProfileSwitcherItem.anneAccount
        processor.state.profileSwitcherState.accounts = [account]
        processor.state.profileSwitcherState.activeAccountId = account.userId
        processor.state.isAutofillingTextToInsertList = true
        processor.state.group = .login
        processor.state.vaultListSections = [
            VaultListSection(
                id: "Items",
                items: [
                    .fixture(
                        cipherListView: .fixture(
                            id: "1",
                            login: .fixture(
                                username: "email@example.com"
                            ),
                            name: "Example",
                            subtitle: "email@example.com",
                        )
                    ),
                    .fixture(cipherListView: .fixture(
                        id: "2",
                        login: .fixture(
                            username: "An equally long subtitle that should also take up more than one line"
                        ),
                        name: "An extra long name that should take up more than one line",
                        subtitle: "An equally long subtitle that should also take up more than one line",
                    )),
                    .fixture(cipherListView: .fixture(
                        id: "3",
                        login: .fixture(
                            username: "email@example.com"
                        ),
                        name: "Example",
                        subtitle: "email@example.com"
                    )),
                    .fixture(cipherListView: .fixture(
                        id: "4",
                        login: .fixture(
                            username: "email@example.com"
                        ),
                        name: "Example",
                        subtitle: "email@example.com"
                    )),
                ],
                name: Localizations.items
            ),
        ]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The populated view renders correctly when registering and excluded credentials has been found.
    @MainActor
    func test_snapshot_vaultAutofillList_populatedWhenRegisteringExcludedCredentialFound() {
        let account = ProfileSwitcherItem.anneAccount
        processor.state.profileSwitcherState.accounts = [account]
        processor.state.profileSwitcherState.activeAccountId = account.userId
        processor.state.isCreatingFido2Credential = true
        processor.state.excludedCredentialIdFound = "1"
        processor.state.vaultListSections = [
            VaultListSection(
                id: Localizations.aPasskeyAlreadyExistsForThisApplication,
                items: [
                    .fixture(cipherListView: .fixture(
                        id: "13",
                        organizationId: "1",
                        login: .fixture(
                            username: "user@bitwarden.com"
                        ),
                        name: "Bitwarden",
                        subtitle: "user@bitwarden.com",
                        attachments: 1,
                    ), fido2CredentialAutofillView: .fixture()),
                ],
                name: Localizations.aPasskeyAlreadyExistsForThisApplication
            ),
        ]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The view renders correctly when searching a term with populated results.
    @MainActor
    func test_snapshot_vaultAutofillList_searching_populated() {
        processor.state.searchText = "Bitwarden"
        processor.state.ciphersForSearch = [
            VaultListSection(
                id: "Passwords",
                items: (1 ... 5).map { id in
                    .init(
                        cipherListView: .fixture(
                            id: String(id),
                            login: .fixture(),
                            name: "Bitwarden"
                        )
                    )!
                },
                name: "Passwords"
            ),
        ]

        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The view renders correctly when searching a term with no results.
    @MainActor
    func test_snapshot_vaultAutofillList_searching_noResults() {
        processor.state.searchText = "Bitwarden"
        processor.state.showNoResults = true

        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }
} // swiftlint:disable:this file_length
