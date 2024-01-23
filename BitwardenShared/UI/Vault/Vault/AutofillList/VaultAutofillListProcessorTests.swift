import BitwardenSdk
import XCTest

@testable import BitwardenShared

class VaultAutofillListProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appExtensionDelegate: MockAppExtensionDelegate!
    var coordinator: MockCoordinator<VaultRoute>!
    var errorReporter: MockErrorReporter!
    var subject: VaultAutofillListProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockAppExtensionDelegate()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()

        subject = VaultAutofillListProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                vaultRepository: vaultRepository
            ),
            state: VaultAutofillListState()
        )
    }

    override func tearDown() {
        super.tearDown()

        appExtensionDelegate = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `cipherTapped(_:)` has the autofill helper handle autofill for the cipher and completes the
    /// autofill request.
    func test_perform_cipherTapped() async {
        let cipher = CipherView.fixture(login: .fixture(password: "PASSWORD", username: "user@bitwarden.com"))
        await subject.perform(.cipherTapped(cipher))

        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequest?.username, "user@bitwarden.com")
        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequest?.password, "PASSWORD")
    }

    /// `cipherTapped(_:)` has the autofill helper handle autofill for the cipher and shows a toast
    /// if a cipher value was copied instead of autofilled.
    func test_perform_cipherTapped_showToast() async throws {
        let cipher = CipherView.fixture(login: .fixture(password: "PASSWORD", username: nil))
        await subject.perform(.cipherTapped(cipher))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.preferredStyle, .actionSheet)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.copyPassword)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        try await alert.tapAction(title: Localizations.copyPassword)

        XCTAssertEqual(subject.state.toast?.text, Localizations.valueHasBeenCopied(Localizations.password))
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

        XCTAssertEqual(subject.state.ciphersForSearch, ciphers)
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

        XCTAssertEqual(subject.state.ciphersForAutofill, ciphers)
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

        XCTAssertEqual(coordinator.routes.last, .addItem(allowTypeSelection: false, group: .login))
    }

    /// `receive(_:)` with `.cancelTapped` notifies the delegate to cancel the extension.
    func test_receive_cancelTapped() {
        subject.receive(.cancelTapped)

        XCTAssertTrue(appExtensionDelegate.didCancelCalled)
    }

    /// `receive(_:)` with `.searchStateChanged` updates the state when the search state changes
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
}
