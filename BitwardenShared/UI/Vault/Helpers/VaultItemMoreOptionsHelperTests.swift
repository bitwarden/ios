import BitwardenSdk
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

class VaultItemMoreOptionsHelperTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
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
        pasteboardService = MockPasteboardService()
        stateService = MockStateService()
        vaultRepository = MockVaultRepository()

        subject = DefaultVaultItemMoreOptionsHelper(
            coordinator: coordinator.asAnyCoordinator(),
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
        stateService.userHasMasterPassword = [account.profile.userId: true]

        var item = try XCTUnwrap(VaultListItem(cipherView: .fixture(type: .card)))

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
        item = try XCTUnwrap(VaultListItem(cipherView: cardWithData))

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
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id))

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
        stateService.userHasMasterPassword = [account.profile.userId: true]

        // A login with data should show the copy and launch actions.
        let loginWithData = CipherView.loginFixture(
            login: .fixture(
                password: "secretPassword",
                uris: [.fixture(uri: URL.example.relativeString, match: nil)],
                username: "username"
            ),
            reprompt: .password
        )
        let item = try XCTUnwrap(VaultListItem(cipherView: loginWithData))

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        var alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 6)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.copyPassword)

        // Test the functionality of the copy user name and password buttons.

        // Copy username copies the username.
        let copyUsernameAction = try XCTUnwrap(alert.alertActions[2])
        await copyUsernameAction.handler?(copyUsernameAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "username")

        // Copy password copies the user's password.
        let copyPasswordAction = try XCTUnwrap(alert.alertActions[3])
        await copyPasswordAction.handler?(copyPasswordAction, [])

        // mock the master password
        authRepository.validatePasswordResult = .success(true)

        // Validate master password re-prompt is shown
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .masterPasswordPrompt { _ in })
        var textField = try XCTUnwrap(alert.alertTextFields.first)
        textField = AlertTextField(id: "password", text: "password")
        let submitAction = try XCTUnwrap(alert.alertActions.first(where: { $0.title == Localizations.submit }))
        await submitAction.handler?(submitAction, [textField])

        XCTAssertEqual(pasteboardService.copiedString, "secretPassword")
    }

    /// `showMoreOptionsAlert()` and press `copyPassword` presents master password re-prompt alert,
    ///  entering wrong password should not allow to copy password.
    @MainActor
    func test_showMoreOptionsAlert_copyPassword_passwordReprompt_invalidPassword() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.userHasMasterPassword = [account.profile.userId: true]

        // A login with data should show the copy and launch actions.
        let loginWithData = CipherView.loginFixture(
            login: .fixture(
                password: "password",
                uris: [.fixture(uri: URL.example.relativeString, match: nil)],
                username: "username"
            ),
            reprompt: .password
        )
        let item = try XCTUnwrap(VaultListItem(cipherView: loginWithData))

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        var alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 6)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.copyPassword)

        // Test the functionality of the copy user name and password buttons.

        // Copy username copies the username.
        let copyUsernameAction = try XCTUnwrap(alert.alertActions[2])
        await copyUsernameAction.handler?(copyUsernameAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "username")

        // Copy password copies the user's password.
        let copyPasswordAction = try XCTUnwrap(alert.alertActions[3])
        await copyPasswordAction.handler?(copyPasswordAction, [])

        // mock the master password
        authRepository.validatePasswordResult = .success(false)

        // Validate master password re-prompt is shown
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .masterPasswordPrompt { _ in })
        try await alert.tapAction(title: Localizations.submit)

        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .defaultAlert(title: Localizations.invalidMasterPassword))

        XCTAssertNotEqual(pasteboardService.copiedString, "secretPassword")
        XCTAssertEqual(pasteboardService.copiedString, "username")
    }

    /// `showMoreOptionsAlert()` and press `copyTotp` presents master password re-prompt
    /// alert and copies the TOTP code when the master password is confirmed.
    @MainActor
    func test_showMoreOptionsAlert_copyTotp_passwordReprompt() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.userHasMasterPassword = [account.profile.userId: true]

        vaultRepository.refreshTOTPCodeResult = .success(
            LoginTOTPState(
                authKeyModel: TOTPKeyModel(authenticatorKey: .standardTotpKey),
                codeModel: TOTPCodeModel(code: "123321", codeGenerationDate: Date(), period: 30)
            )
        )

        let item = try XCTUnwrap(
            VaultListItem(
                cipherView: .fixture(
                    login: .fixture(totp: "totpKey"),
                    reprompt: .password
                )
            )
        )

        var toastToDisplay: Toast?
        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { toastToDisplay = $0 },
            handleOpenURL: { _ in }
        )

        authRepository.validatePasswordResult = .success(true)

        let optionsAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await optionsAlert.tapAction(title: Localizations.copyTotp)

        let repromptAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(repromptAlert, .masterPasswordPrompt(completion: { _ in }))
        try await repromptAlert.tapAction(title: Localizations.submit)

        XCTAssertEqual(pasteboardService.copiedString, "123321")
        XCTAssertEqual(
            toastToDisplay?.text,
            Localizations.valueHasBeenCopied(Localizations.verificationCodeTotp)
        )
    }

    /// `showMoreOptionsAlert()` and press `copyTotp` presents master password re-prompt
    /// alert and displays an alert if the entered master password doesn't match.
    @MainActor
    func test_showMoreOptionsAlert_copyTotp_passwordReprompt_invalidPassword() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.userHasMasterPassword = [account.profile.userId: true]

        vaultRepository.refreshTOTPCodeResult = .success(
            LoginTOTPState(
                authKeyModel: TOTPKeyModel(authenticatorKey: .standardTotpKey),
                codeModel: TOTPCodeModel(code: "123321", codeGenerationDate: Date(), period: 30)
            )
        )

        let item = try XCTUnwrap(
            VaultListItem(
                cipherView: .fixture(
                    login: .fixture(totp: "totpKey"),
                    reprompt: .password
                )
            )
        )

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        authRepository.validatePasswordResult = .success(false)

        let optionsAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await optionsAlert.tapAction(title: Localizations.copyTotp)

        let repromptAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(repromptAlert, .masterPasswordPrompt(completion: { _ in }))
        try await repromptAlert.tapAction(title: Localizations.submit)

        let invalidPasswordAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(invalidPasswordAlert, .defaultAlert(title: Localizations.invalidMasterPassword))
    }

    /// `showMoreOptionsAlert()` and press `copyTotp` copies the TOTP code if the user
    /// doesn't have premium but the organization uses TOTP.
    @MainActor
    func test_showMoreOptionsAlert_copyTotp_organizationUseTotp() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.userHasMasterPassword = [account.profile.userId: true]
        vaultRepository.doesActiveAccountHavePremiumResult = .success(false)
        vaultRepository.refreshTOTPCodeResult = .success(
            LoginTOTPState(
                authKeyModel: TOTPKeyModel(authenticatorKey: .standardTotpKey),
                codeModel: TOTPCodeModel(code: "123321", codeGenerationDate: Date(), period: 30)
            )
        )

        let item = try XCTUnwrap(
            VaultListItem(
                cipherView: .fixture(
                    login: .fixture(totp: "totpKey"),
                    organizationUseTotp: true
                )
            )
        )

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
            toastToDisplay?.text,
            Localizations.valueHasBeenCopied(Localizations.verificationCodeTotp)
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
        let item = try XCTUnwrap(VaultListItem(cipherView: cipherView))

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
        let item = try XCTUnwrap(VaultListItem(cipherView: cipherView))

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

    /// `showMoreOptionsAlert()` logs an error if fetching whether the account has premium fails.
    @MainActor
    func test_showMoreOptionsAlert_doesActiveAccountHavePremiumError() async throws {
        stateService.activeAccount = .fixture()
        vaultRepository.doesActiveAccountHavePremiumResult = .failure(BitwardenTestError.example)

        let item = try XCTUnwrap(VaultListItem(cipherView: .fixture()))
        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `showMoreOptionsAlert()` and press `edit` presents master password re-prompt
    /// alert and navigates to the edit view when the master password is confirmed.
    @MainActor
    func test_showMoreOptionsAlert_edit_passwordReprompt() async throws {
        stateService.activeAccount = .fixture()

        let cipherView = CipherView.fixture(reprompt: .password)
        let item = try XCTUnwrap(VaultListItem(cipherView: cipherView))

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        authRepository.validatePasswordResult = .success(true)

        let optionsAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await optionsAlert.tapAction(title: Localizations.edit)

        let repromptAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(repromptAlert, .masterPasswordPrompt(completion: { _ in }))
        try await repromptAlert.tapAction(title: Localizations.submit)

        XCTAssertEqual(coordinator.routes, [.editItem(cipherView)])
    }

    /// `showMoreOptionsAlert()` and press `edit` presents master password re-prompt
    /// alert and displays an alert if the entered master password doesn't match.
    @MainActor
    func test_showMoreOptionsAlert_edit_passwordReprompt_invalidPassword() async throws {
        stateService.activeAccount = .fixture()

        let cipherView = CipherView.fixture(reprompt: .password)
        let item = try XCTUnwrap(VaultListItem(cipherView: cipherView))

        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        authRepository.validatePasswordResult = .success(false)

        let optionsAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await optionsAlert.tapAction(title: Localizations.edit)

        let repromptAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(repromptAlert, .masterPasswordPrompt(completion: { _ in }))
        try await repromptAlert.tapAction(title: Localizations.submit)

        let invalidPasswordAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(invalidPasswordAlert, .defaultAlert(title: Localizations.invalidMasterPassword))
    }

    /// `showMoreOptionsAlert()` shows the appropriate more options alert for an identity cipher.
    @MainActor
    func test_showMoreOptionsAlert_identity() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.userHasMasterPassword = [account.profile.userId: true]

        let item = try XCTUnwrap(VaultListItem(cipherView: .fixture(type: .identity)))

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
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id))

        // Edit navigates to the edit view.
        let editAction = try XCTUnwrap(alert.alertActions[1])
        await editAction.handler?(editAction, [])
        XCTAssertEqual(coordinator.routes.last, .editItem(.fixture(type: .identity)))
    }

    /// `showMoreOptionsAlert()` shows the appropriate more options alert for a login cipher.
    @MainActor
    func test_showMoreOptionsAlert_login_minimal() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.userHasMasterPassword = [account.profile.userId: true]

        let item = try XCTUnwrap(VaultListItem(cipherView: .fixture(type: .login)))

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
        stateService.userHasMasterPassword = [account.profile.userId: true]

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
        let item = try XCTUnwrap(VaultListItem(cipherView: loginWithData))

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
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id))

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
        stateService.userHasMasterPassword = [account.profile.userId: false]

        // Although the cipher calls for a password reprompt, it won't be shown
        // because the user has no password.
        let login = CipherView.fixture(reprompt: .password)
        let item = try XCTUnwrap(VaultListItem(cipherView: login))

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

        // Edit navigates to the edit view.
        let editAction = try XCTUnwrap(alert.alertActions[1])
        await editAction.handler?(editAction, [])
        XCTAssertEqual(coordinator.routes.last, .editItem(login))
    }

    /// `showMoreOptionsAlert()` logs an error if password validation fails.
    @MainActor
    func test_showMoreOptionsAlert_passwordRepromptValidationError() async throws {
        authRepository.validatePasswordResult = .failure(BitwardenTestError.example)
        stateService.activeAccount = .fixture()

        let cipherView = CipherView.fixture(login: .fixture(password: "password"), reprompt: .password)
        let item = try XCTUnwrap(VaultListItem(cipherView: cipherView))
        await subject.showMoreOptionsAlert(
            for: item,
            handleDisplayToast: { _ in },
            handleOpenURL: { _ in }
        )

        let optionsAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await optionsAlert.tapAction(title: Localizations.copyPassword)

        let repromptAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(repromptAlert, .masterPasswordPrompt(completion: { _ in }))
        try await repromptAlert.tapAction(title: Localizations.submit)

        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `showMoreOptionsAlert()` shows the appropriate more options alert for a secure note cipher.
    @MainActor
    func test_showMoreOptionsAlert_secureNote() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.userHasMasterPassword = [account.profile.userId: true]

        var item = try XCTUnwrap(VaultListItem(cipherView: .fixture(type: .secureNote)))

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
        item = try XCTUnwrap(VaultListItem(cipherView: noteWithData))

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
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id))

        // Edit navigates to the edit view.
        let editAction = try XCTUnwrap(alert.alertActions[1])
        await editAction.handler?(editAction, [])
        XCTAssertEqual(coordinator.routes.last, .editItem(noteWithData))

        // Copy copies the items notes.
        let copyNoteAction = try XCTUnwrap(alert.alertActions[2])
        await copyNoteAction.handler?(copyNoteAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "Test Note")
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
