import BitwardenSdk
import XCTest

@testable import BitwardenShared

class AutofillHelperTests: BitwardenTestCase {
    // MARK: Properties

    var appExtensionDelegate: MockAppExtensionDelegate!
    var coordinator: MockCoordinator<VaultRoute>!
    var errorReporter: MockErrorReporter!
    var pasteboardService: MockPasteboardService!
    var subject: AutofillHelper!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockAppExtensionDelegate()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()
        vaultRepository = MockVaultRepository()

        subject = AutofillHelper(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                vaultRepository: vaultRepository
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        appExtensionDelegate = nil
        coordinator = nil
        errorReporter = nil
        pasteboardService = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `handleCipherForAutofill(cipherListView:)` notifies the delegate of the username and
    /// password to autofill.
    func test_handleCipherForAutofill() async {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: "user@bitwarden.com")
        ))

        let cipher = CipherListView.fixture(id: "1")
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequest?.username, "user@bitwarden.com")
        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequest?.password, "PASSWORD")
    }

    /// `handleCipherForAutofill(cipherListView:)` shows an alert if fetching the cipher results in an error.
    func test_handleCipherForAutofill_fetchCipherError() async {
        let cipher = CipherListView.fixture()
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
    }

    /// `handleCipherForAutofill(cipherListView:)` shows an alert if the cipher is missing an ID.
    func test_handleCipherForAutofill_missingId() async {
        let cipher = CipherListView.fixture(id: nil)

        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
    }

    /// `handleCipherForAutofill(cipherListView:)` shows an alert if the cipher is missing a password.
    func test_handleCipherForAutofill_missingPassword() async throws {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: nil, username: "user@bitwarden.com"),
            name: "Bitwarden Login"
        ))

        let cipher = CipherListView.fixture(id: "1")
        var showToastValue: String?
        await subject.handleCipherForAutofill(cipherListView: cipher) { showToastValue = $0 }

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden Login")
        XCTAssertEqual(alert.preferredStyle, .actionSheet)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.copyUsername)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        try await alert.tapAction(title: Localizations.copyUsername)
        XCTAssertEqual(pasteboardService.copiedString, "user@bitwarden.com")
        XCTAssertEqual(showToastValue, Localizations.valueHasBeenCopied(Localizations.username))
    }

    /// `handleCipherForAutofill(cipherListView:)` shows an alert if the cipher is missing an username.
    func test_handleCipherForAutofill_missingUsername() async throws {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: nil),
            name: "Bitwarden Login"
        ))

        let cipher = CipherListView.fixture(id: "1")
        var showToastValue: String?
        await subject.handleCipherForAutofill(cipherListView: cipher) { showToastValue = $0 }

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden Login")
        XCTAssertEqual(alert.preferredStyle, .actionSheet)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.copyPassword)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        try await alert.tapAction(title: Localizations.copyPassword)
        XCTAssertEqual(pasteboardService.copiedString, "PASSWORD")
        XCTAssertEqual(showToastValue, Localizations.valueHasBeenCopied(Localizations.password))
    }

    /// `handleCipherForAutofill(cipherListView:)` shows an alert if the cipher is missing an
    /// username and password.
    func test_handleCipherForAutofill_missingUsernameAndPassword() async throws {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: nil, username: nil)
        ))

        let cipher = CipherListView.fixture(id: "1")
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .defaultAlert(title: Localizations.noUsernamePasswordConfigured))
    }

    /// `handleCipherForAutofill(cipherListView:)` displays an alert if the cipher requires a master
    /// password reprompt.
    func test_handleCipherForAutofill_passwordReprompt() async throws {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: "user@bitwarden.com"),
            name: "Bitwarden Login",
            reprompt: .password
        ))

        let cipher = CipherListView.fixture(id: "1")
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .masterPasswordPrompt { _ in })
        var textField = try XCTUnwrap(alert.alertTextFields.first)
        textField = AlertTextField(id: "password", text: "password")
        let submitAction = try XCTUnwrap(alert.alertActions.first(where: { $0.title == Localizations.submit }))
        await submitAction.handler?(submitAction, [textField])

        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequest?.username, "user@bitwarden.com")
        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequest?.password, "PASSWORD")
    }

    /// `handleCipherForAutofill(cipherListView:)` displays an alert if the password reprompt
    /// validation fails.
    func test_handleCipherForAutofill_passwordReprompt_invalidPassword() async throws {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: "user@bitwarden.com"),
            name: "Bitwarden Login",
            reprompt: .password
        ))
        vaultRepository.validatePasswordResult = .success(false)

        let cipher = CipherListView.fixture(id: "1")
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        var alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .masterPasswordPrompt { _ in })
        try await alert.tapAction(title: Localizations.submit)

        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .defaultAlert(title: Localizations.invalidMasterPassword))
    }
}
