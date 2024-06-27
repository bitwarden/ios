import BitwardenSdk
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

class VaultItemSelectionProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var pasteboardService: MockPasteboardService!
    var stateService: MockStateService!
    var subject: VaultItemSelectionProcessor!
    var userVerificationHelper: MockUserVerificationHelper!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()
        stateService = MockStateService()
        userVerificationHelper = MockUserVerificationHelper()
        vaultRepository = MockVaultRepository()

        subject = VaultItemSelectionProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                stateService: stateService,
                vaultRepository: vaultRepository
            ),
            state: VaultItemSelectionState(
                iconBaseURL: nil,
                otpAuthModel: OTPAuthModel(otpAuthKey: .otpAuthUriKeyComplete)!
            ),
            userVerificationHelper: userVerificationHelper
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
        userVerificationHelper = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `itemAdded()` requests the coordinator dismiss the view.
    func test_itemAdded() {
        let shouldDismiss = subject.itemAdded()

        XCTAssertEqual(coordinator.routes, [.dismiss])
        XCTAssertFalse(shouldDismiss)
    }

    /// `itemUpdated()` requests the coordinator dismiss the view.
    func test_itemUpdated() {
        let shouldDismiss = subject.itemUpdated()

        XCTAssertEqual(coordinator.routes, [.dismiss])
        XCTAssertFalse(shouldDismiss)
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

    /// `perform(_:)` with `.morePressed` and press `copyPassword` presents master password re-prompt alert.
    func test_perform_morePressed_copyPassword_rePromptMasterPassword() async throws {
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

        await subject.perform(.morePressed(item))

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

    /// `perform(_:)` with `.morePressed` and press `copyPassword` presents master password re-prompt alert,
    ///  entering wrong password should not allow to copy password.
    func test_perform_morePressed_copyPassword_passwordReprompt_invalidPassword() async throws {
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

        await subject.perform(.morePressed(item))

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

    /// `perform(_:)` with `.morePressed` and press `copyTotp` presents master password re-prompt
    /// alert and copies the TOTP code when the master password is confirmed.
    func test_perform_morePressed_copyTotp_passwordReprompt() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.userHasMasterPassword = [account.profile.userId: true]

        vaultRepository.refreshTOTPCodeResult = .success(
            LoginTOTPState(
                authKeyModel: TOTPKeyModel(authenticatorKey: .base32Key)!,
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

        await subject.perform(.morePressed(item))

        authRepository.validatePasswordResult = .success(true)

        let optionsAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await optionsAlert.tapAction(title: Localizations.copyTotp)

        let repromptAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(repromptAlert, .masterPasswordPrompt(completion: { _ in }))
        try await repromptAlert.tapAction(title: Localizations.submit)

        XCTAssertEqual(pasteboardService.copiedString, "123321")
        XCTAssertEqual(
            subject.state.toast?.text,
            Localizations.valueHasBeenCopied(Localizations.verificationCodeTotp)
        )
    }

    /// `perform(_:)` with `.morePressed` and press `copyTotp` presents master password re-prompt
    /// alert and displays an alert if the entered master password doesn't match.
    func test_perform_morePressed_copyTotp_passwordReprompt_invalidPassword() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.userHasMasterPassword = [account.profile.userId: true]

        vaultRepository.refreshTOTPCodeResult = .success(
            LoginTOTPState(
                authKeyModel: TOTPKeyModel(authenticatorKey: .base32Key)!,
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

        await subject.perform(.morePressed(item))

        authRepository.validatePasswordResult = .success(false)

        let optionsAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await optionsAlert.tapAction(title: Localizations.copyTotp)

        let repromptAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(repromptAlert, .masterPasswordPrompt(completion: { _ in }))
        try await repromptAlert.tapAction(title: Localizations.submit)

        let invalidPasswordAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(invalidPasswordAlert, .defaultAlert(title: Localizations.invalidMasterPassword))
    }

    /// `perform(_:)` with `.morePressed` and press `copyTotp` copies the TOTP code if the user
    /// doesn't have premium but the organization uses TOTP.
    func test_perform_morePressed_copyTotp_organizationUseTotp() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.doesActiveAccountHavePremiumResult = .success(false)
        stateService.userHasMasterPassword = [account.profile.userId: true]
        vaultRepository.refreshTOTPCodeResult = .success(
            LoginTOTPState(
                authKeyModel: TOTPKeyModel(authenticatorKey: .base32Key)!,
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

        await subject.perform(.morePressed(item))

        let optionsAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await optionsAlert.tapAction(title: Localizations.copyTotp)

        XCTAssertEqual(pasteboardService.copiedString, "123321")
        XCTAssertEqual(
            subject.state.toast?.text,
            Localizations.valueHasBeenCopied(Localizations.verificationCodeTotp)
        )
    }

    /// `perform(_:)` with `.morePressed` shows the appropriate more options alert for a login cipher.
    func test_perform_morePressed_login_full() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.userHasMasterPassword = [account.profile.userId: true]

        vaultRepository.refreshTOTPCodeResult = .success(
            LoginTOTPState(
                authKeyModel: TOTPKeyModel(authenticatorKey: .base32Key)!,
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

        await subject.perform(.morePressed(item))

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
        XCTAssertEqual(subject.state.url, .example)
    }

    /// `perform(_:)` with `.morePressed` shows the appropriate more options alert for a login cipher.
    func test_perform_morePressed_login_minimal() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.userHasMasterPassword = [account.profile.userId: true]

        let item = try XCTUnwrap(VaultListItem(cipherView: .fixture(type: .login)))

        // If the login item has no username, password, or url, only the view and add buttons should display.
        vaultRepository.fetchCipherResult = .success(.loginFixture())

        await subject.perform(.morePressed(item))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 3)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.cancel)
    }

    /// `perform(_:)` with `.morePressed` does not show the password re-prompt alert when the user has no password.
    func test_perform_morePressed_noPassword() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.userHasMasterPassword = [account.profile.userId: false]

        // Although the cipher calls for a password reprompt, it won't be shown
        // because the user has no password.
        let login = CipherView.fixture(reprompt: .password)
        let item = try XCTUnwrap(VaultListItem(cipherView: login))

        // An identity option can be viewed or edited.
        vaultRepository.fetchCipherResult = .success(.fixture(type: .identity))

        await subject.perform(.morePressed(item))

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
        XCTAssertEqual(
            coordinator.events.last,
            .switchAccount(
                isAutomatic: false,
                userId: "1",
                authCompletionRoute: .tab(.vault(.vaultItemSelection(.fixtureExample)))
            )
        )
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

    /// `perform(_:)` with `.search()` performs a vault search and updates the state with the results.
    func test_perform_search() throws {
        let vaultItems: [VaultListItem] = try [
            XCTUnwrap(VaultListItem(cipherView: .fixture(id: "1"))),
            XCTUnwrap(VaultListItem(cipherView: .fixture(id: "2"))),
            XCTUnwrap(VaultListItem(cipherView: .fixture(id: "3"))),
        ]
        vaultRepository.searchVaultListSubject.value = vaultItems

        let task = Task {
            await subject.perform(.search("Bit"))
        }

        waitFor(!subject.state.searchResults.isEmpty)
        task.cancel()

        XCTAssertEqual(subject.state.searchResults, vaultItems)
        XCTAssertFalse(subject.state.showNoResults)
    }

    /// `perform(_:)` with `.search()` doesn't perform a search if the search string is empty.
    func test_perform_search_empty() async {
        await subject.perform(.search(" "))

        XCTAssertTrue(subject.state.searchResults.isEmpty)
        XCTAssertFalse(subject.state.showNoResults)
    }

    /// `perform(_:)` with `.search()` performs a vault search and logs an error if one occurs.
    func test_perform_search_error() {
        let task = Task {
            await subject.perform(.search("example"))
        }

        vaultRepository.searchVaultListSubject.send(completion: .failure(BitwardenTestError.example))
        waitFor(!coordinator.alertShown.isEmpty)
        task.cancel()

        XCTAssertTrue(subject.state.searchResults.isEmpty)
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

        XCTAssertTrue(subject.state.searchResults.isEmpty)
        XCTAssertTrue(subject.state.showNoResults)
    }

    /// `perform(_:)` with `.streamVaultItems` streams the list of vault items.
    func test_perform_streamVaultItems() throws {
        let vaultItems: [VaultListItem] = try [
            XCTUnwrap(VaultListItem(cipherView: .fixture(id: "1"))),
            XCTUnwrap(VaultListItem(cipherView: .fixture(id: "2"))),
            XCTUnwrap(VaultListItem(cipherView: .fixture(id: "3"))),
        ]
        vaultRepository.searchVaultListSubject.value = vaultItems

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
                    name: Localizations.matchingItems
                ),
            ]
        )
    }

    /// `perform(_:)` with `.streamVaultItems` doesn't create an empty section if no results are returned.
    func test_perform_streamVaultItems_empty() throws {
        subject.state.vaultListSections = [
            VaultListSection(id: "", items: [.fixture()], name: Localizations.matchingItems),
        ]
        vaultRepository.searchVaultListSubject.value = []

        let task = Task {
            await subject.perform(.streamVaultItems)
        }

        waitFor(subject.state.vaultListSections.isEmpty)
        task.cancel()

        XCTAssertTrue(subject.state.vaultListSections.isEmpty)
    }

    /// `perform(_:)` with `.streamVaultItems` logs an error if one occurs.
    func test_perform_streamVaultItems_error() {
        let task = Task {
            await subject.perform(.streamVaultItems)
        }

        vaultRepository.searchVaultListSubject.send(completion: .failure(BitwardenTestError.example))
        waitFor(!coordinator.alertShown.isEmpty)
        task.cancel()

        XCTAssertTrue(subject.state.vaultListSections.isEmpty)
        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.vaultListItemTapped` navigates to the edit item screen for the cipher
    /// with the OTP key added.
    func test_perform_vaultListItemTapped() async throws {
        let cipher = CipherView.loginFixture()
        let vaultListItem = try XCTUnwrap(VaultListItem(cipherView: cipher))

        await subject.perform(.vaultListItemTapped(vaultListItem))

        let updatedCipher = CipherView.loginFixture(login: .fixture(totp: .otpAuthUriKeyComplete))
        XCTAssertEqual(coordinator.routes, [.editItem(updatedCipher)])
        XCTAssertTrue(coordinator.contexts.last as? VaultItemSelectionProcessor === subject)
        XCTAssertFalse(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `perform(_:)` with `.vaultListItemTapped` displays an alert and logs an error if one occurs.
    func test_perform_vaultListItemTapped_error() async throws {
        let cipher = CipherView.loginFixture(reprompt: .password)
        let vaultListItem = try XCTUnwrap(VaultListItem(cipherView: cipher))
        userVerificationHelper.verifyMasterPasswordResult = .failure(BitwardenTestError.example)

        await subject.perform(.vaultListItemTapped(vaultListItem))

        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [BitwardenTestError.example])
    }

    /// `perform(_:)` with `.vaultListItemTapped` doesn't show an alert if user verification was cancelled.
    func test_perform_vaultListItemTapped_errorCancellation() async throws {
        let cipher = CipherView.loginFixture(reprompt: .password)
        let vaultListItem = try XCTUnwrap(VaultListItem(cipherView: cipher))
        userVerificationHelper.verifyMasterPasswordResult = .failure(UserVerificationError.cancelled)

        await subject.perform(.vaultListItemTapped(vaultListItem))

        XCTAssertTrue(coordinator.alertShown.isEmpty)
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `perform(_:)` with `.vaultListItemTapped` reprompts the user for their master password if
    /// necessary before navigating to the edit item screen.
    func test_perform_vaultListItemTapped_masterPasswordReprompt() async throws {
        let cipher = CipherView.loginFixture(reprompt: .password)
        let vaultListItem = try XCTUnwrap(VaultListItem(cipherView: cipher))

        await subject.perform(.vaultListItemTapped(vaultListItem))

        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)

        let updatedCipher = CipherView.loginFixture(login: .fixture(totp: .otpAuthUriKeyComplete), reprompt: .password)
        XCTAssertEqual(coordinator.routes, [.editItem(updatedCipher)])
        XCTAssertTrue(coordinator.contexts.last as? VaultItemSelectionProcessor === subject)
    }

    /// `perform(_:)` with `.vaultListItemTapped` doesn't navigate to the edit item screen if the
    /// user's master password couldn't be verified.
    func test_perform_vaultListItemTapped_masterPasswordRepromptInvalid() async throws {
        let cipher = CipherView.loginFixture(reprompt: .password)
        let vaultListItem = try XCTUnwrap(VaultListItem(cipherView: cipher))
        userVerificationHelper.verifyMasterPasswordResult = .success(.notVerified)

        await subject.perform(.vaultListItemTapped(vaultListItem))

        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `perform(_:)` with `.vaultListItemTapped` shows an alert if the vault list item doesn't contain a login.
    func test_perform_vaultListItemTapped_notLogin() async throws {
        let vaultListItem = try XCTUnwrap(VaultListItem(cipherView: .cardFixture()))

        await subject.perform(.vaultListItemTapped(vaultListItem))

        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
    }

    /// `receive(_:)` with `.addTapped` navigates to the add item view.
    func test_receive_addTapped() {
        subject.receive(.addTapped)

        XCTAssertEqual(
            coordinator.routes.last,
            .addItem(
                allowTypeSelection: false,
                group: .login,
                newCipherOptions: NewCipherOptions(
                    name: "Example",
                    totpKey: .otpAuthUriKeyComplete
                )
            )
        )
        XCTAssertTrue(coordinator.contexts.last as? VaultItemSelectionProcessor === subject)
    }

    /// `receive(_:)` with `.addTapped` hides the profile switcher if it's visible.
    func test_receive_addTapped_hidesProfileSwitcher() {
        subject.state.profileSwitcherState.isVisible = true

        subject.receive(.addTapped)

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.cancelTapped` notifies the coordinator to dismiss the view.
    func test_receive_cancelTapped() {
        subject.receive(.cancelTapped)

        XCTAssertEqual(coordinator.routes, [.dismiss])
    }

    /// `receive(_:)` with `.clearURL` clears the url in the state.
    func test_receive_clearURL() {
        subject.state.url = .example
        subject.receive(.clearURL)
        XCTAssertNil(subject.state.url)
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
        subject.state.searchResults = [.fixture()]
        subject.state.showNoResults = true

        subject.receive(.searchStateChanged(isSearching: false))

        XCTAssertTrue(subject.state.searchResults.isEmpty)
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
}
