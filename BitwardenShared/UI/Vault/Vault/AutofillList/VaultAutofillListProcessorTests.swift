import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

class VaultAutofillListProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appExtensionDelegate: MockAppExtensionDelegate!
    var authRepository: MockAuthRepository!
    var clientService: MockClientService!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var fido2CredentialStore: MockFido2CredentialStore!
    var fido2UserInterfaceHelper: MockFido2UserInterfaceHelper!
    var pasteboardService: MockPasteboardService!
    var stateService: MockStateService!
    var subject: VaultAutofillListProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockAppExtensionDelegate()
        authRepository = MockAuthRepository()
        clientService = MockClientService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        fido2CredentialStore = MockFido2CredentialStore()
        fido2UserInterfaceHelper = MockFido2UserInterfaceHelper()
        pasteboardService = MockPasteboardService()
        stateService = MockStateService()
        vaultRepository = MockVaultRepository()

        subject = VaultAutofillListProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                clientService: clientService,
                errorReporter: errorReporter,
                fido2CredentialStore: fido2CredentialStore,
                fido2UserInterfaceHelper: fido2UserInterfaceHelper,
                pasteboardService: pasteboardService,
                stateService: stateService,
                vaultRepository: vaultRepository
            ),
            state: VaultAutofillListState()
        )
    }

    override func tearDown() {
        super.tearDown()

        appExtensionDelegate = nil
        authRepository = nil
        clientService = nil
        coordinator = nil
        errorReporter = nil
        fido2CredentialStore = nil
        fido2UserInterfaceHelper = nil
        pasteboardService = nil
        stateService = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `getter:isAutofillingFromList` returns `false` when delegate is not a Fido2 one.
    @MainActor
    func test_isAutofillingFromList_falseNoFido2Delegate() async throws {
        XCTAssertFalse(subject.isAutofillingFromList)
    }

    /// `vaultItemTapped(_:)` has the autofill helper handle autofill for the cipher and completes the
    /// autofill request.
    @MainActor
    func test_perform_vaultItemTapped() async {
        vaultRepository.fetchCipherResult = .success(CipherView.fixture(
            login: .fixture(password: "PASSWORD", username: "user@bitwarden.com"))
        )
        let vaultListItem = VaultListItem(
            cipherListView: .fixture()
        )!
        await subject.perform(.vaultItemTapped(vaultListItem))

        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequestUsername, "user@bitwarden.com")
        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequestPassword, "PASSWORD")
        XCTAssertFalse(fido2UserInterfaceHelper.pickedCredentialForCreationMocker.called)
    }

    /// `vaultItemTapped(_:)` shows an alert when tapping on a cipher which failed to decrypt.
    @MainActor
    func test_perform_vaultItemTapped_cipherDecryptionFailure() async throws {
        let cipherListView = CipherListView.fixture(name: Localizations.errorCannotDecrypt)
        let item = VaultListItem.fixture(cipherListView: cipherListView)

        await subject.perform(.vaultItemTapped(item))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .cipherDecryptionFailure(cipherIds: ["1"]) { _ in })

        try await alert.tapAction(title: Localizations.copyErrorReport)
        XCTAssertEqual(
            pasteboardService.copiedString,
            """
            \(Localizations.decryptionError)
            \(Localizations.bitwardenCouldNotDecryptThisVaultItemDescriptionLong)

            1
            """
        )
    }

    /// `vaultItemTapped(_:)` has the autofill helper handle autofill for the cipher and shows a toast
    /// if a cipher value was copied instead of autofilled.
    @MainActor
    func test_perform_vaultItemTapped_showToast() async throws {
        vaultRepository.fetchCipherResult = .success(CipherView.fixture(
            login: .fixture(password: "PASSWORD", username: nil))
        )
        let vaultListItem = VaultListItem(
            cipherListView: .fixture()
        )!
        await subject.perform(.vaultItemTapped(vaultListItem))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.preferredStyle, .actionSheet)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.copyPassword)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        try await alert.tapAction(title: Localizations.copyPassword)

        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.valueHasBeenCopied(Localizations.password)))
    }

    /// `perform(_:)` with `.loadData` loads the profile switcher state.
    @MainActor
    func test_perform_loadData_profileSwitcher() async {
        authRepository.profileSwitcherState = ProfileSwitcherState(
            accounts: [.anneAccount],
            activeAccountId: ProfileSwitcherItem.anneAccount.userId,
            allowLockAndLogout: false,
            isVisible: true
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

    /// `perform(_:)` with `.profileSwitcher(.accountPressed)` updates the profile switcher's
    /// visibility and navigates to switch account.
    @MainActor
    func test_perform_profileSwitcher_accountPressed() async {
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
        XCTAssertEqual(coordinator.events.last, .switchAccount(isAutomatic: false, userId: "1"))
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
    func test_perform_profileSwitcher_toggleProfilesViewVisibility() async {
        subject.state.profileSwitcherState.isVisible = false
        await subject.perform(.profileSwitcher(.requestedProfileSwitcher(visible: true)))

        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }

    /// `perform(_:)` with `.search()` performs a cipher search and updates the state with the results.
    @MainActor
    func test_perform_search() {
        let ciphers: [CipherListView] = [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")]
        let expectedSection = VaultListSection(
            id: "",
            items: ciphers.compactMap { VaultListItem(cipherListView: $0) },
            name: ""
        )
        vaultRepository.searchCipherAutofillSubject.value = VaultListData(sections: [expectedSection])

        let task = Task {
            await subject.perform(.search("Bit"))
        }

        waitFor(!subject.state.ciphersForSearch.isEmpty)
        task.cancel()

        XCTAssertEqual(subject.state.ciphersForSearch, [expectedSection])
        XCTAssertFalse(subject.state.showNoResults)
    }

    /// `perform(_:)` with `.search()` doesn't perform a search if the search string is empty.
    @MainActor
    func test_perform_search_empty() async {
        await subject.perform(.search(" "))

        XCTAssertTrue(subject.state.ciphersForSearch.isEmpty)
        XCTAssertFalse(subject.state.showNoResults)
    }

    /// `perform(_:)` with `.search()` performs a cipher search and logs an error if one occurs.
    @MainActor
    func test_perform_search_error() {
        let task = Task {
            await subject.perform(.search("example"))
        }

        vaultRepository.searchCipherAutofillSubject.send(completion: .failure(BitwardenTestError.example))
        waitFor(!coordinator.alertShown.isEmpty)
        task.cancel()

        XCTAssertTrue(subject.state.ciphersForSearch.isEmpty)
        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.search()` sets the `showNoResults` flag if the search resulted in no results.
    @MainActor
    func test_perform_search_noResults() {
        let task = Task {
            await subject.perform(.search("example"))
        }
        waitFor(subject.state.showNoResults)
        task.cancel()

        XCTAssertTrue(subject.state.ciphersForSearch.isEmpty)
        XCTAssertTrue(subject.state.showNoResults)
    }

    /// `perform(_:)` with `.streamAutofillItems` streams the list of autofill ciphers.
    @MainActor
    func test_perform_streamAutofillItems() {
        let ciphers: [CipherListView] = [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")]
        let expectedSection = VaultListSection(
            id: "",
            items: ciphers.compactMap { VaultListItem(cipherListView: $0) },
            name: ""
        )
        vaultRepository.ciphersAutofillSubject.value = VaultListData(sections: [expectedSection])

        let task = Task {
            await subject.perform(.streamAutofillItems)
        }

        waitFor(!subject.state.vaultListSections.isEmpty)
        task.cancel()

        XCTAssertEqual(subject.state.vaultListSections, [expectedSection])
    }

    /// `perform(_:)` with `.streamAutofillItems` logs an error if one occurs.
    @MainActor
    func test_perform_streamAutofillItems_error() {
        let task = Task {
            await subject.perform(.streamAutofillItems)
        }

        vaultRepository.ciphersAutofillSubject.send(completion: .failure(BitwardenTestError.example))
        waitFor(!coordinator.alertShown.isEmpty)
        task.cancel()

        XCTAssertTrue(subject.state.ciphersForSearch.isEmpty)
        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.streamShowWebIcons` requests the value of the show
    /// web icons parameter from the state service.
    @MainActor
    func test_perform_streamShowWebIcons() {
        let task = Task {
            await subject.perform(.streamShowWebIcons)
        }

        stateService.showWebIconsSubject.send(false)
        waitFor(subject.state.showWebIcons == false)

        task.cancel()
    }

    /// `receive(_:)` with `.addTapped` navigates to the add item view.
    @MainActor
    func test_receive_addTapped() {
        subject.receive(.addTapped(fromFAB: false))

        XCTAssertEqual(
            coordinator.routes.last,
            .addItem(group: .login, newCipherOptions: NewCipherOptions(), type: .login)
        )
    }

    /// `receive(_:)` with `.addTapped` hides the profile switcher if it's visible.
    @MainActor
    func test_receive_addTapped_hidesProfileSwitcher() {
        subject.state.profileSwitcherState.isVisible = true

        subject.receive(.addTapped(fromFAB: false))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.addTapped` navigates to the add item view when adding from toolbar.
    @MainActor
    func test_receive_addTapped_fromToolbar() {
        subject.receive(.addTapped(fromFAB: true))

        XCTAssertEqual(
            coordinator.routes.last,
            .addItem(group: .login, newCipherOptions: NewCipherOptions(), type: .login)
        )
    }

    /// `receive(_:)` with `.addTapped` hides the profile switcher if it's visible when adding from toolbar.
    @MainActor
    func test_receive_addTapped_hidesProfileSwitcher_fromToolbar() {
        subject.state.profileSwitcherState.isVisible = true

        subject.receive(.addTapped(fromFAB: true))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.cancelTapped` notifies the delegate to cancel the extension.
    @MainActor
    func test_receive_cancelTapped() {
        subject.receive(.cancelTapped)

        XCTAssertTrue(appExtensionDelegate.didCancelCalled)
    }

    /// `receive(_:)` with `.profileSwitcher(.backgroundPressed)` turns off the Profile Switcher Visibility.
    @MainActor
    func test_receive_profileSwitcher_backgroundPressed() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.profileSwitcher(.backgroundPressed))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.profileSwitcher(.logout)` does nothing.
    @MainActor
    func test_receive_profileSwitcher_logout() async {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.profileSwitcher(.accessibility(.logout(.fixture()))))

        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.searchStateChanged` updates the state when the search state changes.
    @MainActor
    func test_receive_searchStateChanged() {
        subject.receive(.searchStateChanged(isSearching: true))

        subject.receive(.searchTextChanged("Bit"))
        subject.state.ciphersForSearch = [VaultListSection(id: "test", items: [.fixture()], name: "test")]
        subject.state.showNoResults = true

        subject.receive(.searchStateChanged(isSearching: true))

        XCTAssertTrue(subject.state.ciphersForSearch.isEmpty)
        XCTAssertTrue(subject.state.searchText.isEmpty)
        XCTAssertFalse(subject.state.showNoResults)
    }

    /// `receive(_:)` with `.searchStateChanged(isSearching: true)` hides the profile switcher.
    @MainActor
    func test_receive_searchStateChanged_true_profilesHide() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.searchStateChanged(isSearching: true))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
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

    /// `showAlert(_:onDismissed:)` shows the alert with the coordinator.
    @MainActor
    func test_showAlert_withOnDismissed() async throws {
        subject.showAlert(Alert(title: "Test", message: "testing"), onDismissed: nil)
        XCTAssertFalse(coordinator.alertShown.isEmpty)
    }

    /// `showAlert(_:)` shows the alert with the coordinator.
    @MainActor
    func test_showAlert() async throws {
        subject.showAlert(Alert(title: "Test", message: "testing"))
        XCTAssertFalse(coordinator.alertShown.isEmpty)
    }
} // swiftlint:disable:this file_length
