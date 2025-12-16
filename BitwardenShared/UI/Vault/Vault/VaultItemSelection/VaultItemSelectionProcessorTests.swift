import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import InlineSnapshotTesting
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// swiftlint:disable file_length

class VaultItemSelectionProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var pasteboardService: MockPasteboardService!
    var searchProcessorMediator: MockSearchProcessorMediator!
    var searchProcessorMediatorFactory: MockSearchProcessorMediatorFactory!
    var stateService: MockStateService!
    var subject: VaultItemSelectionProcessor!
    var userVerificationHelper: MockUserVerificationHelper!
    var vaultItemMoreOptionsHelper: MockVaultItemMoreOptionsHelper!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()

        searchProcessorMediator = MockSearchProcessorMediator()
        searchProcessorMediatorFactory = MockSearchProcessorMediatorFactory()
        searchProcessorMediatorFactory.makeReturnValue = searchProcessorMediator

        stateService = MockStateService()
        userVerificationHelper = MockUserVerificationHelper()
        vaultItemMoreOptionsHelper = MockVaultItemMoreOptionsHelper()
        vaultRepository = MockVaultRepository()

        subject = VaultItemSelectionProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                searchProcessorMediatorFactory: searchProcessorMediatorFactory,
                stateService: stateService,
                vaultRepository: vaultRepository,
            ),
            state: VaultItemSelectionState(
                iconBaseURL: nil,
                totpKeyModel: .fixtureExample,
            ),
            userVerificationHelper: userVerificationHelper,
            vaultItemMoreOptionsHelper: vaultItemMoreOptionsHelper,
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        coordinator = nil
        errorReporter = nil
        pasteboardService = nil
        searchProcessorMediator = nil
        searchProcessorMediatorFactory = nil
        stateService = nil
        subject = nil
        userVerificationHelper = nil
        vaultItemMoreOptionsHelper = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `init(coordinator:services:state:userVerificationHelper:vaultItemMoreOptionsHelper:)` initializes
    /// the search process mediator.
    func test_init() {
        XCTAssertTrue(searchProcessorMediatorFactory.makeCalled)
        XCTAssertNotNil(searchProcessorMediator.setDelegateReceivedDelegate)
    }

    /// `itemAdded()` requests the coordinator dismiss the view.
    @MainActor
    func test_itemAdded() {
        let shouldDismiss = subject.itemAdded()

        XCTAssertEqual(coordinator.routes, [.dismiss])
        XCTAssertFalse(shouldDismiss)
    }

    /// `itemUpdated()` requests the coordinator dismiss the view.
    @MainActor
    func test_itemUpdated() {
        let shouldDismiss = subject.itemUpdated()

        XCTAssertEqual(coordinator.routes, [.dismiss])
        XCTAssertFalse(shouldDismiss)
    }

    /// `perform(_:)` with `.loadData` loads the profile switcher state.
    @MainActor
    func test_perform_loadData_profileSwitcher() async {
        authRepository.profileSwitcherState = ProfileSwitcherState(
            accounts: [.anneAccount],
            activeAccountId: ProfileSwitcherItem.anneAccount.userId,
            allowLockAndLogout: false,
            isVisible: true,
        )

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.profileSwitcherState.accounts, [.anneAccount])
    }

    /// `perform(_:)` with `.loadData` loads an empty state the profile switcher.
    @MainActor
    func test_perform_loadData_profileSwitcher_empty() async {
        authRepository.profileSwitcherState = .empty()

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.profileSwitcherState, .empty(shouldAlwaysHideAddAccount: true))
    }

    /// `perform(_:)` with `.morePressed` has the vault item more options helper display the alert.
    @MainActor
    func test_perform_morePressed() async throws {
        await subject.perform(.morePressed(.fixture()))

        XCTAssertTrue(vaultItemMoreOptionsHelper.showMoreOptionsAlertCalled)
        XCTAssertNotNil(vaultItemMoreOptionsHelper.showMoreOptionsAlertHandleDisplayToast)
        XCTAssertNotNil(vaultItemMoreOptionsHelper.showMoreOptionsAlertHandleOpenURL)

        let toast = Toast(title: Localizations.valueHasBeenCopied(Localizations.password))
        vaultItemMoreOptionsHelper.showMoreOptionsAlertHandleDisplayToast?(toast)
        XCTAssertEqual(subject.state.toast, toast)

        let url = URL.example
        vaultItemMoreOptionsHelper.showMoreOptionsAlertHandleOpenURL?(url)
        XCTAssertEqual(subject.state.url, url)
    }

    /// `perform(_:)` with `.profileSwitcher(.accountPressed)` updates the profile switcher's
    /// visibility and navigates to switch account.
    @MainActor
    func test_perform_profileSwitcher_accountPressed() async throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-25906 - Backfill tests for new account switcher
            throw XCTSkip("This test requires iOS 18.6 or earlier")
        }

        subject.state.profileSwitcherState.isVisible = true
        await subject.perform(.profileSwitcher(.accountPressed(ProfileSwitcherItem.fixture(userId: "1"))))
        authRepository.activeAccount = .fixture(profile: .fixture(userId: "42"))
        authRepository.altAccounts = [
            .fixture(),
        ]
        authRepository.vaultTimeout = [
            "1": .fiveMinutes,
            "42": .immediately,
        ]

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(
            coordinator.events.last,
            .switchAccount(
                isAutomatic: false,
                userId: "1",
                authCompletionRoute: .tab(.vault(.vaultItemSelection(.fixtureExample))),
            ),
        )
    }

    /// `perform(_:)` with `.profileSwitcher(.lock)` does nothing.
    @MainActor
    func test_perform_profileSwitcher_lock() async {
        subject.state.profileSwitcherState.isVisible = true
        await subject.perform(.profileSwitcher(.accessibility(.lock(.fixture()))))

        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }

    /// `perform(_:)` with `.profileSwitcher(.requestedProfileSwitcher(visible:))` updates the state correctly.
    @MainActor
    func test_perform_profileSwitcher_toggleProfilesViewVisibility() async throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-25906 - Backfill tests for new account switcher
            throw XCTSkip("This test requires iOS 18.6 or earlier")
        }

        subject.state.profileSwitcherState.isVisible = false
        await subject.perform(.profileSwitcher(.requestedProfileSwitcher(visible: true)))

        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }

    /// `perform(.search)` with a keyword should indicate the search processor mediator that the filter changed.
    @MainActor
    func test_perform_search() async throws {
        await subject.perform(.search("example"))

        XCTAssertEqual(
            searchProcessorMediator.updateFilterReceivedFilter,
            VaultListFilter(
                filterType: .allVaults,
                group: .login,
                searchText: "example",
            ),
        )
    }

    /// `perform(_:)` with `.search()` doesn't perform a search if the search string is empty.
    @MainActor
    func test_perform_search_empty() async {
        await subject.perform(.search(" "))

        XCTAssertTrue(subject.state.searchResults.isEmpty)
        XCTAssertFalse(subject.state.showNoResults)
        XCTAssertFalse(searchProcessorMediator.updateFilterCalled)
    }

    /// `perform(_:)` with `.streamVaultItems` streams the list of vault items.
    @MainActor
    func test_perform_streamVaultItems() throws {
        let vaultItems: [VaultListItem] = try [
            XCTUnwrap(VaultListItem(cipherListView: .fixture(id: "1"))),
            XCTUnwrap(VaultListItem(cipherListView: .fixture(id: "2"))),
            XCTUnwrap(VaultListItem(cipherListView: .fixture(id: "3"))),
        ]
        let expectedSection = VaultListSection(
            id: Localizations.matchingItems,
            items: vaultItems,
            name: Localizations.matchingItems,
        )
        vaultRepository.vaultListSubject.value = VaultListData(sections: [expectedSection])

        let task = Task {
            await subject.perform(.streamVaultItems)
        }

        waitFor(!subject.state.vaultListSections.isEmpty)
        task.cancel()

        XCTAssertEqual(
            subject.state.vaultListSections,
            [
                VaultListSection(
                    id: Localizations.matchingItems,
                    items: vaultItems,
                    name: Localizations.matchingItems,
                ),
            ],
        )
        XCTAssertEqual(
            vaultRepository.vaultListFilter,
            VaultListFilter(
                filterType: .allVaults,
                group: .login,
                options: [.isInPickerMode],
                searchText: "Example",
            ),
        )
    }

    /// `perform(_:)` with `.streamVaultItems` doesn't create an empty section if no results are returned.
    @MainActor
    func test_perform_streamVaultItems_empty() throws {
        subject.state.vaultListSections = [
            VaultListSection(id: "", items: [.fixture()], name: Localizations.matchingItems),
        ]
        vaultRepository.vaultListSubject.value = VaultListData(sections: [])

        let task = Task {
            await subject.perform(.streamVaultItems)
        }

        waitFor(subject.state.vaultListSections.isEmpty)
        task.cancel()

        XCTAssertTrue(subject.state.vaultListSections.isEmpty)
    }

    /// `perform(_:)` with `.streamVaultItems` logs an error if one occurs.
    @MainActor
    func test_perform_streamVaultItems_error() {
        let task = Task {
            await subject.perform(.streamVaultItems)
        }

        vaultRepository.vaultListSubject.send(completion: .failure(BitwardenTestError.example))
        waitFor(!coordinator.alertShown.isEmpty)
        task.cancel()

        XCTAssertTrue(subject.state.vaultListSections.isEmpty)
        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.vaultListItemTapped` navigates to the edit item screen for the cipher
    /// with the OTP key added.
    @MainActor
    func test_perform_vaultListItemTapped() async throws {
        let rawCipher = Cipher.fixture(
            id: "8675",
            login: .fixture(),
            type: .login,
        )
        let cipher = CipherListView(cipher: rawCipher)
        let vaultListItem = try XCTUnwrap(VaultListItem(cipherListView: cipher))
        vaultRepository.fetchCipherResult = .success(CipherView(cipher: rawCipher))

        await subject.perform(.vaultListItemTapped(vaultListItem))

        let updatedCipher = CipherView.loginFixture(login: .fixture(totp: .otpAuthUriKeyComplete))
        XCTAssertEqual(coordinator.routes, [.editItem(updatedCipher)])
        XCTAssertTrue(coordinator.contexts.last as? VaultItemSelectionProcessor === subject)
        XCTAssertFalse(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `perform(_:)` with `.vaultListItemTapped` displays an alert and logs an error if one occurs.
    @MainActor
    func test_perform_vaultListItemTapped_error() async throws {
        let cipher = CipherListView.fixture(
            login: .fixture(),
            reprompt: BitwardenSdk.CipherRepromptType.password,
        )
        let vaultListItem = try XCTUnwrap(VaultListItem(cipherListView: cipher))
        userVerificationHelper.verifyMasterPasswordResult = .failure(BitwardenTestError.example)

        await subject.perform(.vaultListItemTapped(vaultListItem))

        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [BitwardenTestError.example])
    }

    /// `perform(_:)` with `.vaultListItemTapped` doesn't show an alert if user verification was cancelled.
    @MainActor
    func test_perform_vaultListItemTapped_errorCancellation() async throws {
        let cipher = CipherListView.fixture(
            login: .fixture(),
            reprompt: BitwardenSdk.CipherRepromptType.password,
        )
        let vaultListItem = try XCTUnwrap(VaultListItem(cipherListView: cipher))
        userVerificationHelper.verifyMasterPasswordResult = .failure(UserVerificationError.cancelled)

        await subject.perform(.vaultListItemTapped(vaultListItem))

        XCTAssertTrue(coordinator.alertShown.isEmpty)
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `perform(_:)` with `.vaultListItemTapped` reprompts the user for their master password if
    /// necessary before navigating to the edit item screen.
    @MainActor
    func test_perform_vaultListItemTapped_masterPasswordReprompt() async throws {
        let rawCipher = Cipher.fixture(
            id: "8675",
            login: .fixture(),
            reprompt: .password,
            type: .login,
        )
        let cipher = CipherListView(cipher: rawCipher)
        let vaultListItem = try XCTUnwrap(VaultListItem(cipherListView: cipher))
        vaultRepository.fetchCipherResult = .success(CipherView(cipher: rawCipher))

        await subject.perform(.vaultListItemTapped(vaultListItem))

        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)

        let updatedCipher = CipherView.loginFixture(login: .fixture(totp: .otpAuthUriKeyComplete), reprompt: .password)
        XCTAssertEqual(coordinator.routes, [.editItem(updatedCipher)])
        XCTAssertTrue(coordinator.contexts.last as? VaultItemSelectionProcessor === subject)
    }

    /// `perform(_:)` with `.vaultListItemTapped` doesn't navigate to the edit item screen if the
    /// user's master password couldn't be verified.
    @MainActor
    func test_perform_vaultListItemTapped_masterPasswordRepromptInvalid() async throws {
        let cipher = CipherListView.fixture(
            login: .fixture(),
            reprompt: BitwardenSdk.CipherRepromptType.password,
        )
        let vaultListItem = try XCTUnwrap(VaultListItem(cipherListView: cipher))
        userVerificationHelper.verifyMasterPasswordResult = .success(.notVerified)

        await subject.perform(.vaultListItemTapped(vaultListItem))

        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `perform(_:)` with `.vaultListItemTapped` shows an alert if the vault list item doesn't contain a login.
    @MainActor
    func test_perform_vaultListItemTapped_notLogin() async throws {
        let vaultListItem = try XCTUnwrap(VaultListItem(cipherListView: .fixture(
            type: .card(.init(brand: nil)),
        )))

        await subject.perform(.vaultListItemTapped(vaultListItem))

        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
    }

    /// `onNewSearchResults(data:)` updates the state's search results with the new items.
    @MainActor
    func test_onNewSearchResults() {
        subject.onNewSearchResults(
            data: VaultListData(
                sections: [
                    VaultListSection(
                        id: "SearchResults",
                        items: [
                            VaultListItem(cipherListView: .fixture(name: "Result 1")),
                            VaultListItem(cipherListView: .fixture(name: "Result 2")),
                            VaultListItem(cipherListView: .fixture(name: "Result 3")),
                        ].compactMap(\.self),
                        name: "Search Results",
                    ),
                ],
            ),
        )

        assertInlineSnapshot(of: subject.state.searchResults.dump(), as: .lines) {
            """
            - Cipher: Result 1
            - Cipher: Result 2
            - Cipher: Result 3
            """
        }
        XCTAssertFalse(subject.state.showNoResults)
    }

    /// `onNewSearchResults(data:)` updates the state's search to empty when there are no sections in the data.
    @MainActor
    func test_onNewSearchResults_noSections() {
        subject.onNewSearchResults(
            data: VaultListData(
                sections: [],
            ),
        )

        assertInlineSnapshot(of: subject.state.searchResults.dump(), as: .lines) {
            """
            (empty)
            """
        }
        XCTAssertTrue(subject.state.showNoResults)
    }

    /// `receive(_:)` with `.addTapped` navigates to the add item view.
    @MainActor
    func test_receive_addTapped() {
        subject.receive(.addTapped)

        XCTAssertEqual(
            coordinator.routes.last,
            .addItem(
                group: .login,
                newCipherOptions: NewCipherOptions(
                    name: "Example",
                    totpKey: .otpAuthUriKeyComplete,
                ),
                type: .login,
            ),
        )
        XCTAssertTrue(coordinator.contexts.last as? VaultItemSelectionProcessor === subject)
    }

    /// `receive(_:)` with `.addTapped` hides the profile switcher if it's visible.
    @MainActor
    func test_receive_addTapped_hidesProfileSwitcher() {
        subject.state.profileSwitcherState.isVisible = true

        subject.receive(.addTapped)

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.cancelTapped` notifies the coordinator to dismiss the view.
    @MainActor
    func test_receive_cancelTapped() {
        subject.receive(.cancelTapped)

        XCTAssertEqual(coordinator.routes, [.dismiss])
    }

    /// `receive(_:)` with `.clearURL` clears the url in the state.
    @MainActor
    func test_receive_clearURL() {
        subject.state.url = .example
        subject.receive(.clearURL)
        XCTAssertNil(subject.state.url)
    }

    /// `receive(_:)` with `.profileSwitcher(.backgroundPressed)` turns off the Profile Switcher Visibility.
    @MainActor
    func test_receive_profileSwitcher_backgroundPressed() throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-25906 - Backfill tests for new account switcher
            throw XCTSkip("This test requires iOS 18.6 or earlier")
        }

        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.profileSwitcher(.backgroundTapped))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.profileSwitcher(.logout)` does nothing.
    @MainActor
    func test_receive_profileSwitcher_logout() async {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.profileSwitcher(.accessibility(.logout(.fixture()))))

        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.searchStateChanged(isSearching: false)` doesn't hide the profile switcher
    /// and stops the search process in the mediator.
    @MainActor
    func test_receive_searchStateChanged() {
        subject.state.searchText = "Search text"
        subject.state.searchResults = [.fixture()]
        subject.state.showNoResults = true

        subject.receive(.searchStateChanged(isSearching: false))

        XCTAssertTrue(subject.state.searchResults.isEmpty)
        XCTAssertTrue(subject.state.searchText.isEmpty)
        XCTAssertFalse(subject.state.showNoResults)
        XCTAssertFalse(searchProcessorMediator.startSearchingCalled)
        XCTAssertTrue(searchProcessorMediator.stopSearchingCalled)
    }

    /// `receive(_:)` with `.searchStateChanged(isSearching: true)` hides the profile switcher
    /// and starts the search process in the mediator.
    @MainActor
    func test_receive_searchStateChanged_true_profilesHide() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.searchStateChanged(isSearching: true))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(coordinator.routes, [.dismiss])
        XCTAssertTrue(searchProcessorMediator.startSearchingCalled)
        XCTAssertFalse(searchProcessorMediator.stopSearchingCalled)
    }

    /// `receive(_:)` with `.searchTextChanged` updates the state's search text value.
    @MainActor
    func test_receive_searchTextChanged() {
        subject.receive(.searchTextChanged("Bit"))
        XCTAssertEqual(subject.state.searchText, "Bit")

        subject.receive(.searchTextChanged("Bitwarden"))
        XCTAssertEqual(subject.state.searchText, "Bitwarden")
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    @MainActor
    func test_receive_toastShown() {
        let toast = Toast(title: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    // MARK: ProfileSwitcherHandler

    /// `dismissProfileSwitcher` calls the coordinator to dismiss the profile switcher.
    @MainActor
    func test_dismissProfileSwitcher() {
        subject.dismissProfileSwitcher()

        XCTAssertEqual(coordinator.routes, [.dismiss])
    }

    /// `showProfileSwitcher` calls the coordinator to show the profile switcher.
    @MainActor
    func test_showProfileSwitcher() {
        subject.showProfileSwitcher()

        XCTAssertEqual(coordinator.routes, [.viewProfileSwitcher])
    }
}
