import BitwardenSdk
import XCTest

@testable import BitwardenShared

class VaultAutofillListProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appExtensionDelegate: MockAppExtensionDelegate!
    var authRepository: MockAuthRepository!
    var clientService: MockClientService!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var fido2CredentialStore: MockFido2CredentialStore!
    var fido2UserInterfaceHelper: MockFido2UserInterfaceHelper!
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
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `vaultItemTapped(_:)` has the autofill helper handle autofill for the cipher and completes the
    /// autofill request.
    func test_perform_vaultItemTapped() async {
        let vaultListItem = VaultListItem(
            cipherView: CipherView.fixture(login: .fixture(password: "PASSWORD", username: "user@bitwarden.com"))
        )!
        await subject.perform(.vaultItemTapped(vaultListItem))

        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequestUsername, "user@bitwarden.com")
        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequestPassword, "PASSWORD")
        XCTAssertFalse(fido2UserInterfaceHelper.pickedCredentialForCreationMocker.called)
    }

    /// `vaultItemTapped(_:)` has the autofill helper handle autofill for the cipher and shows a toast
    /// if a cipher value was copied instead of autofilled.
    func test_perform_vaultItemTapped_showToast() async throws {
        let vaultListItem = VaultListItem(
            cipherView: CipherView.fixture(login: .fixture(password: "PASSWORD", username: nil))
        )!
        await subject.perform(.vaultItemTapped(vaultListItem))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.preferredStyle, .actionSheet)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.copyPassword)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        try await alert.tapAction(title: Localizations.copyPassword)

        XCTAssertEqual(subject.state.toast?.text, Localizations.valueHasBeenCopied(Localizations.password))
    }

    /// `perform(_:)` with `.loadData` loads the profile switcher state.
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
    func test_perform_loadData_profileSwitcher_empty() async {
        authRepository.profileSwitcherState = .empty()

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.profileSwitcherState, .empty(shouldAlwaysHideAddAccount: true))
    }

    /// `perform(_:)` with `.profileSwitcher(.accountPressed)` updates the profile switcher's
    /// visibility and navigates to switch account.
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
    func test_perform_profileSwitcher_lock() async {
        subject.state.profileSwitcherState.isVisible = true
        await subject.perform(.profileSwitcher(.accessibility(.lock(.fixture()))))

        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }

    /// `perform(_:)` with `.profileSwitcher(.requestedProfileSwitcher(visible:))` updates the state correctly.
    func test_perform_profileSwitcher_toggleProfilesViewVisibility() async {
        subject.state.profileSwitcherState.isVisible = false
        await subject.perform(.profileSwitcher(.requestedProfileSwitcher(visible: true)))

        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }

    /// `perform(_:)` with `.search()` performs a cipher search and updates the state with the results.
    func test_perform_search() {
        let ciphers: [CipherView] = [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")]
        vaultRepository.searchCipherAutofillSubject.value = ciphers

        let task = Task {
            await subject.perform(.search("Bit"))
        }

        waitFor(!subject.state.ciphersForSearch.isEmpty)
        task.cancel()

        XCTAssertEqual(subject.state.ciphersForSearch, ciphers.compactMap { VaultListItem(cipherView: $0) })
        XCTAssertFalse(subject.state.showNoResults)
    }

    /// `perform(_:)` with `.search()` doesn't perform a search if the search string is empty.
    func test_perform_search_empty() async {
        await subject.perform(.search(" "))

        XCTAssertTrue(subject.state.ciphersForSearch.isEmpty)
        XCTAssertFalse(subject.state.showNoResults)
    }

    /// `perform(_:)` with `.search()` performs a cipher search and logs an error if one occurs.
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
    func test_perform_streamAutofillItems() {
        let ciphers: [CipherView] = [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")]
        vaultRepository.ciphersAutofillSubject.value = ciphers

        let task = Task {
            await subject.perform(.streamAutofillItems)
        }

        waitFor(!subject.state.ciphersForAutofill.isEmpty)
        task.cancel()

        XCTAssertEqual(subject.state.ciphersForAutofill, ciphers.compactMap { VaultListItem(cipherView: $0) })
    }

    /// `perform(_:)` with `.streamAutofillItems` logs an error if one occurs.
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

    /// `receive(_:)` with `.addTapped` navigates to the add item view.
    func test_receive_addTapped() {
        subject.receive(.addTapped)

        XCTAssertEqual(
            coordinator.routes.last,
            .addItem(allowTypeSelection: false, group: .login, newCipherOptions: NewCipherOptions())
        )
    }

    /// `receive(_:)` with `.addTapped` hides the profile switcher if it's visible.
    func test_receive_addTapped_hidesProfileSwitcher() {
        subject.state.profileSwitcherState.isVisible = true

        subject.receive(.addTapped)

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.cancelTapped` notifies the delegate to cancel the extension.
    func test_receive_cancelTapped() {
        subject.receive(.cancelTapped)

        XCTAssertTrue(appExtensionDelegate.didCancelCalled)
    }

    /// `receive(_:)` with `.profileSwitcher(.backgroundPressed)` turns off the Profile Switcher Visibility.
    func test_receive_profileSwitcher_backgroundPressed() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.profileSwitcher(.backgroundPressed))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.profileSwitcher(.logout)` does nothing.
    func test_receive_profileSwitcher_logout() async {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.profileSwitcher(.accessibility(.logout(.fixture()))))

        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.profileSwitcher(.scrollOffsetChanged)` updates the scroll offset.
    func test_receive_profileSwitcher_scrollOffset() {
        subject.state.profileSwitcherState.scrollOffset = .zero
        subject.receive(.profileSwitcher(.scrollOffsetChanged(CGPoint(x: 10, y: 10))))
        XCTAssertEqual(subject.state.profileSwitcherState.scrollOffset, CGPoint(x: 10, y: 10))
    }

    /// `receive(_:)` with `.searchStateChanged` updates the state when the search state changes.
    func test_receive_searchStateChanged() {
        subject.receive(.searchStateChanged(isSearching: true))

        subject.receive(.searchTextChanged("Bit"))
        subject.state.ciphersForSearch = [.fixture()]
        subject.state.showNoResults = true

        subject.receive(.searchStateChanged(isSearching: true))

        XCTAssertTrue(subject.state.ciphersForSearch.isEmpty)
        XCTAssertTrue(subject.state.searchText.isEmpty)
        XCTAssertFalse(subject.state.showNoResults)
    }

    /// `receive(_:)` with `.searchStateChanged(isSearching: true)` hides the profile switcher.
    func test_receive_searchStateChanged_true_profilesHide() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.searchStateChanged(isSearching: true))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.searchTextChanged` updates the state's search text value.
    func test_receive_searchTextChanged() {
        subject.receive(.searchTextChanged("Bit"))
        XCTAssertEqual(subject.state.searchText, "Bit")

        subject.receive(.searchTextChanged("Bitwarden"))
        XCTAssertEqual(subject.state.searchText, "Bitwarden")
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    func test_receive_toastShown() {
        let toast = Toast(text: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// `showAlert(_:onDismissed:)` shows the alert with the coordinator.
    func test_showAlert_withOnDismissed() async throws {
        subject.showAlert(Alert(title: "Test", message: "testing"), onDismissed: nil)
        XCTAssertFalse(coordinator.alertShown.isEmpty)
    }

    /// `showAlert(_:)` shows the alert with the coordinator.
    func test_showAlert() async throws {
        subject.showAlert(Alert(title: "Test", message: "testing"))
        XCTAssertFalse(coordinator.alertShown.isEmpty)
    }
}
