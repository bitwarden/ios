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
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: "user@bitwarden.com")
        ))

        let cipher = CipherListView.fixture()
        await subject.perform(.cipherTapped(cipher))

        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequest?.username, "user@bitwarden.com")
        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequest?.password, "PASSWORD")
    }

    /// `cipherTapped(_:)` has the autofill helper handle autofill for the cipher and shows a toast
    /// if a cipher value was copied instead of autofilled.
    func test_perform_cipherTapped_showToast() async throws {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: nil)
        ))

        let cipher = CipherListView.fixture()
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

    /// `receive(_:)` with `.cancelTapped` notifies the delegate to cancel the extension.
    func test_receive_dismissPressed() {
        subject.receive(.cancelTapped)

        XCTAssertTrue(appExtensionDelegate.didCancelCalled)
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
