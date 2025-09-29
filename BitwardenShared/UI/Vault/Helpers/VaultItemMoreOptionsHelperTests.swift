import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

class VaultItemMoreOptionsHelperTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var masterPasswordRepromptHelper: MockMasterPasswordRepromptHelper!
    var pasteboardService: MockPasteboardService!
    var stateService: MockStateService!
    var subject: VaultItemMoreOptionsHelper!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        masterPasswordRepromptHelper = MockMasterPasswordRepromptHelper()
        pasteboardService = MockPasteboardService()
        stateService = MockStateService()
        vaultRepository = MockVaultRepository()

        subject = DefaultVaultItemMoreOptionsHelper(
            coordinator: coordinator.asAnyCoordinator(),
            masterPasswordRepromptHelper: masterPasswordRepromptHelper,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                stateService: stateService,
                vaultRepository: vaultRepository
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        coordinator = nil
        errorReporter = nil
        masterPasswordRepromptHelper = nil
        pasteboardService = nil
        stateService = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `showMoreOptionsAlert()` shows the appropriate more options alert for a card cipher.
    @MainActor
    func test_showMoreOptionsAlert_card() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        var item = try XCTUnwrap(VaultListItem(cipherListView: .fixture(type: .card(.init(brand: nil)))))

        // If the card item has no number or code, only the view and add buttons should display.
        vaultRepository.fetchCipherResult = .success(.cardFixture())

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        var alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 3)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.cancel)

        // A card with data should show the copy actions.
        let cardWithData = CipherView.cardFixture(card: .fixture(
            code: "123",
            number: "123456789"
        ))
        vaultRepository.fetchCipherResult = .success(cardWithData)
        item = try XCTUnwrap(VaultListItem(cipherListView: .fixture()))

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 5)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.copyNumber)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.copySecurityCode)
        XCTAssertEqual(alert.alertActions[4].title, Localizations.cancel)

        // Test the functionality of the buttons.

        // View navigates to the view item view.
        let viewAction = try XCTUnwrap(alert.alertActions[0])
        await viewAction.handler?(viewAction, [])
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id, masterPasswordRepromptCheckCompleted: true))

        // Edit navigates to the edit view.
        let editAction = try XCTUnwrap(alert.alertActions[1])
        await editAction.handler?(editAction, [])
        XCTAssertEqual(coordinator.routes.last, .editItem(cardWithData))

        // Copy number copies the card's number.
        let copyNumberAction = try XCTUnwrap(alert.alertActions[2])
        await copyNumberAction.handler?(copyNumberAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "123456789")

        // Copy security code copies the card's security code.
        let copyCodeAction = try XCTUnwrap(alert.alertActions[3])
        await copyCodeAction.handler?(copyCodeAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "123")
    }

    /// `showMoreOptionsAlert()` and press `copyPassword` presents master password re-prompt alert.
    @MainActor
    func test_showMoreOptionsAlert_copyPassword_rePromptMasterPassword() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        masterPasswordRepromptHelper.repromptForMasterPasswordAutoComplete = false

        // A login with data should show the copy and launch actions.
        let loginWithData = CipherView.loginFixture(
            login: .fixture(
                password: "secretPassword",
                uris: [.fixture(uri: URL.example.relativeString, match: nil)],
                username: "username"
            ),
            reprompt: .password
        )
        vaultRepository.fetchCipherResult = .success(loginWithData)
        let item = try XCTUnwrap(VaultListItem(cipherListView: .fixture()))

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 6)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.copyPassword)

        // Test the functionality of the copy user name and password buttons.

        // Copy username copies the username.
        let copyUsernameAction = try XCTUnwrap(alert.alertActions[2])
        await copyUsernameAction.handler?(copyUsernameAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "username")
        pasteboardService.copiedString = nil

        // Copy password copies the user's password.
        let copyPasswordAction = try XCTUnwrap(alert.alertActions[3])
        await copyPasswordAction.handler?(copyPasswordAction, [])

        // Validate master password re-prompt is shown.
        XCTAssertEqual(masterPasswordRepromptHelper.repromptForMasterPasswordCipherView, loginWithData)

        // Validate string is copied only if master password reprompt completes successfully.
        XCTAssertNil(pasteboardService.copiedString)
        await masterPasswordRepromptHelper.repromptForMasterPasswordCompletion?()
        XCTAssertEqual(pasteboardService.copiedString, "secretPassword")
    }

    /// `showMoreOptionsAlert()` and press `copyTotp` presents master password re-prompt
    /// alert and copies the TOTP code when the master password is confirmed.
    @MainActor
    func test_showMoreOptionsAlert_copyTotp_passwordReprompt() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        masterPasswordRepromptHelper.repromptForMasterPasswordAutoComplete = false

        vaultRepository.refreshTOTPCodeResult = .success(
            LoginTOTPState(
                authKeyModel: TOTPKeyModel(authenticatorKey: .standardTotpKey),
                codeModel: TOTPCodeModel(code: "123321", codeGenerationDate: Date(), period: 30)
            )
        )
        let cipherView = CipherView.fixture(
            login: .fixture(totp: "totpKey"),
            reprompt: .password
        )
        vaultRepository.fetchCipherResult = .success(cipherView)

        let item = try XCTUnwrap(VaultListItem(cipherListView: .fixture()))

        var toastToDisplay: Toast?
        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { toastToDisplay = $0 },
            handleOpenURL: { _ in }
        )

        let optionsAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await optionsAlert.tapAction(title: Localizations.copyTotp)

        // Validate master password re-prompt is shown.
        XCTAssertEqual(masterPasswordRepromptHelper.repromptForMasterPasswordCipherView, cipherView)

        // Validate string is copied only if master password reprompt completes successfully.
        XCTAssertNil(pasteboardService.copiedString)
        await masterPasswordRepromptHelper.repromptForMasterPasswordCompletion?()
        XCTAssertEqual(pasteboardService.copiedString, "123321")
        XCTAssertEqual(
            toastToDisplay,
            Toast(title: Localizations.valueHasBeenCopied(Localizations.verificationCodeTotp))
        )
    }

    /// `showMoreOptionsAlert()` and press `copyTotp` copies the TOTP code if the user
    /// doesn't have premium but the organization uses TOTP.
    @MainActor
    func test_showMoreOptionsAlert_copyTotp_organizationUseTotp() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        vaultRepository.doesActiveAccountHavePremiumResult = false
        vaultRepository.refreshTOTPCodeResult = .success(
            LoginTOTPState(
                authKeyModel: TOTPKeyModel(authenticatorKey: .standardTotpKey),
                codeModel: TOTPCodeModel(code: "123321", codeGenerationDate: Date(), period: 30)
            )
        )

        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(totp: "totpKey"),
            organizationUseTotp: true

        ))
        let item = try XCTUnwrap(VaultListItem(cipherListView: .fixture()))

        var toastToDisplay: Toast?
        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { toastToDisplay = $0 },
            handleOpenURL: { _ in }
        )

        let optionsAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await optionsAlert.tapAction(title: Localizations.copyTotp)

        XCTAssertEqual(pasteboardService.copiedString, "123321")
        XCTAssertEqual(
            toastToDisplay,
            Toast(title: Localizations.valueHasBeenCopied(Localizations.verificationCodeTotp))
        )
    }

    /// `showMoreOptionsAlert()` and press `copyTotp` logs an error if refreshing the TOTP code
    /// doesn't return a code.
    @MainActor
    func test_showMoreOptionsAlert_copyTotp_refreshTOTPEmpty() async throws {
        stateService.activeAccount = .fixture()
        vaultRepository.refreshTOTPCodeResult = .success(
            LoginTOTPState(authKeyModel: TOTPKeyModel(authenticatorKey: .standardTotpKey))
        )

        let cipherView = CipherView.fixture(login: .fixture(totp: "totpKey"))
        vaultRepository.fetchCipherResult = .success(cipherView)
        let item = try XCTUnwrap(VaultListItem(cipherListView: .fixture()))

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        let optionsAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await optionsAlert.tapAction(title: Localizations.copyTotp)

        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors as? [TOTPServiceError], [.unableToGenerateCode(nil)])
    }

    /// `showMoreOptionsAlert()` and press `copyTotp` logs an error if refreshing the TOTP code fails.
    @MainActor
    func test_showMoreOptionsAlert_copyTotp_refreshTOTPError() async throws {
        stateService.activeAccount = .fixture()
        vaultRepository.refreshTOTPCodeResult = .failure(BitwardenTestError.example)

        let cipherView = CipherView.fixture(login: .fixture(totp: "totpKey"))
        vaultRepository.fetchCipherResult = .success(cipherView)
        let item = try XCTUnwrap(VaultListItem(cipherListView: .fixture()))

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        let optionsAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await optionsAlert.tapAction(title: Localizations.copyTotp)

        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `showMoreOptionsAlert()` and press `edit` presents master password re-prompt
    /// alert and navigates to the edit view when the master password is confirmed.
    @MainActor
    func test_showMoreOptionsAlert_edit_passwordReprompt() async throws {
        stateService.activeAccount = .fixture()
        masterPasswordRepromptHelper.repromptForMasterPasswordAutoComplete = false

        let cipherView = CipherView.fixture(reprompt: .password)
        vaultRepository.fetchCipherResult = .success(cipherView)
        let item = try XCTUnwrap(VaultListItem(cipherListView: .fixture()))

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        authRepository.validatePasswordResult = .success(true)

        let optionsAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await optionsAlert.tapAction(title: Localizations.edit)

        // Validate master password re-prompt is shown.
        XCTAssertEqual(masterPasswordRepromptHelper.repromptForMasterPasswordCipherView, cipherView)

        // Validate string is copied only if master password reprompt completes successfully.
        XCTAssertTrue(coordinator.routes.isEmpty)
        await masterPasswordRepromptHelper.repromptForMasterPasswordCompletion?()
        XCTAssertEqual(coordinator.routes, [.editItem(cipherView)])
    }

    /// `showMoreOptionsAlert()` shows the appropriate more options alert for an identity cipher.
    @MainActor
    func test_showMoreOptionsAlert_identity() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        vaultRepository.fetchCipherResult = .success(.fixture(type: .identity))
        let item = try XCTUnwrap(VaultListItem(cipherListView: .fixture(type: .identity)))

        // An identity option can be viewed or edited.
        vaultRepository.fetchCipherResult = .success(.fixture(type: .identity))

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 3)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.cancel)

        // Test the functionality of the buttons.

        // View navigates to the view item view.
        let viewAction = try XCTUnwrap(alert.alertActions[0])
        await viewAction.handler?(viewAction, [])
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id, masterPasswordRepromptCheckCompleted: true))

        // Edit navigates to the edit view.
        let editAction = try XCTUnwrap(alert.alertActions[1])
        await editAction.handler?(editAction, [])
        XCTAssertEqual(coordinator.routes.last, .editItem(.fixture(type: .identity)))
    }

    /// `showMoreOptionsAlert()` shows the appropriate more options alert for a deleted login cipher.
    @MainActor
    func test_showMoreOptionsAlert_login_deleted() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.userHasMasterPassword = [account.profile.userId: true]

        vaultRepository.fetchCipherResult = .success(.fixture(deletedDate: .now, type: .login))
        let item = try XCTUnwrap(VaultListItem(cipherListView: .fixture(login: .fixture())))

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)
    }

    /// `showMoreOptionsAlert()` shows the appropriate more options alert for a login cipher.
    @MainActor
    func test_showMoreOptionsAlert_login_minimal() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        vaultRepository.fetchCipherResult = .success(.fixture(type: .login))
        let item = try XCTUnwrap(VaultListItem(cipherListView: .fixture(login: .fixture())))

        // If the login item has no username, password, or url, only the view and add buttons should display.
        vaultRepository.fetchCipherResult = .success(.loginFixture())

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 3)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.cancel)
    }

    /// `showMoreOptionsAlert()` shows the appropriate more options alert for a login cipher.
    @MainActor
    func test_showMoreOptionsAlert_morePressed_login_full() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        vaultRepository.refreshTOTPCodeResult = .success(
            LoginTOTPState(
                authKeyModel: TOTPKeyModel(authenticatorKey: .standardTotpKey),
                codeModel: TOTPCodeModel(code: "123321", codeGenerationDate: Date(), period: 30)
            )
        )

        let loginWithData = CipherView.loginFixture(login: .fixture(
            password: "password",
            uris: [.fixture(uri: URL.example.relativeString, match: nil)],
            username: "username",
            totp: "totpKey"
        ))
        vaultRepository.fetchCipherResult = .success(loginWithData)
        let item = try XCTUnwrap(VaultListItem(cipherListView: .fixture()))

        var urlToOpen: URL?
        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { urlToOpen = $0 }
        )

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 7)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.copyUsername)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.copyPassword)
        XCTAssertEqual(alert.alertActions[4].title, Localizations.copyTotp)
        XCTAssertEqual(alert.alertActions[5].title, Localizations.launch)
        XCTAssertEqual(alert.alertActions[6].title, Localizations.cancel)

        // Test the functionality of the buttons.

        // View navigates to the view item view.
        let viewAction = try XCTUnwrap(alert.alertActions[0])
        await viewAction.handler?(viewAction, [])
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id, masterPasswordRepromptCheckCompleted: true))

        // Edit navigates to the edit view.
        let editAction = try XCTUnwrap(alert.alertActions[1])
        await editAction.handler?(editAction, [])
        XCTAssertEqual(coordinator.routes.last, .editItem(loginWithData))

        // Copy username copies the username.
        let copyUsernameAction = try XCTUnwrap(alert.alertActions[2])
        await copyUsernameAction.handler?(copyUsernameAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "username")

        // Copy password copies the user's username.
        let copyPasswordAction = try XCTUnwrap(alert.alertActions[3])
        await copyPasswordAction.handler?(copyPasswordAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "password")

        // Copy TOTP copies the user's TOTP code.
        let copyTotpAction = try XCTUnwrap(alert.alertActions[4])
        await copyTotpAction.handler?(copyPasswordAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "123321")

        // Launch action set's the url to open.
        let launchAction = try XCTUnwrap(alert.alertActions[5])
        await launchAction.handler?(launchAction, [])
        XCTAssertEqual(urlToOpen, .example)
    }

    /// `showMoreOptionsAlert()` does not show the password re-prompt alert when the user has no password.
    @MainActor
    func test_showMoreOptionsAlert_noPassword() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        // Although the cipher calls for a password reprompt, it won't be shown
        // because the user has no password.
        let login = CipherView.fixture(reprompt: .password)
        vaultRepository.fetchCipherResult = .success(login)
        let item = try XCTUnwrap(VaultListItem(cipherListView: .fixture(reprompt: .password)))

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 3)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.cancel)

        // Edit navigates to the edit view.
        let editAction = try XCTUnwrap(alert.alertActions[1])
        await editAction.handler?(editAction, [])
        XCTAssertEqual(coordinator.routes.last, .editItem(login))
    }

    /// `showMoreOptionsAlert()` shows the appropriate more options alert for a secure note cipher.
    @MainActor
    func test_showMoreOptionsAlert_secureNote() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        vaultRepository.fetchCipherResult = .success(.fixture(type: .secureNote))
        var item = try XCTUnwrap(VaultListItem(cipherListView: .fixture()))

        // If the secure note has no value, only the view and add buttons should display.
        vaultRepository.fetchCipherResult = .success(.fixture(type: .secureNote))

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        var alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 3)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.cancel)

        // A note with data should show the copy action.
        let noteWithData = CipherView.fixture(notes: "Test Note", type: .secureNote)
        vaultRepository.fetchCipherResult = .success(noteWithData)
        item = try XCTUnwrap(VaultListItem(cipherListView: .fixture()))

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 4)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.copyNotes)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.cancel)

        // Test the functionality of the buttons.

        // View navigates to the view item view.
        let viewAction = try XCTUnwrap(alert.alertActions[0])
        await viewAction.handler?(viewAction, [])
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id, masterPasswordRepromptCheckCompleted: true))

        // Edit navigates to the edit view.
        let editAction = try XCTUnwrap(alert.alertActions[1])
        await editAction.handler?(editAction, [])
        XCTAssertEqual(coordinator.routes.last, .editItem(noteWithData))

        // Copy copies the items notes.
        let copyNoteAction = try XCTUnwrap(alert.alertActions[2])
        await copyNoteAction.handler?(copyNoteAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "Test Note")
    }

    /// `showMoreOptionsAlert()` does not show the password re-prompt alert when the cipher fetched is `nil`.
    @MainActor
    func test_showMoreOptionsAlert_noCipher() async throws {
        vaultRepository.fetchCipherResult = .success(nil)
        let item = try XCTUnwrap(VaultListItem(cipherListView: .fixture()))

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        XCTAssertTrue(coordinator.alertShown.isEmpty)
    }

    /// `showMoreOptionsAlert()` does not show the password re-prompt alert when fetching cipher throws.
    @MainActor
    func test_showMoreOptionsAlert_fetchCipherThrows() async throws {
        vaultRepository.fetchCipherResult = .failure(BitwardenTestError.example)
        let item = try XCTUnwrap(VaultListItem(cipherListView: .fixture()))

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, Localizations.anErrorHasOccurred)
    }
}

class MockVaultItemMoreOptionsHelper: VaultItemMoreOptionsHelper {
    var showMoreOptionsAlertCalled = false
    var showMoreOptionsAlertHandleDisplayToast: ((Toast) -> Void)?
    var showMoreOptionsAlertHandleOpenURL: ((URL) -> Void)?

    func showMoreOptionsAlert(
        for item: VaultListItem,
        handleDisplayToast: @escaping (Toast) -> Void,
        handleOpenURL: @escaping (URL) -> Void
    ) async {
        showMoreOptionsAlertCalled = true
        showMoreOptionsAlertHandleDisplayToast = handleDisplayToast
        showMoreOptionsAlertHandleOpenURL = handleOpenURL
    }
}
