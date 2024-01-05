import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - ViewItemProcessorTests

class ViewItemProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Propteries

    var coordinator: MockCoordinator<VaultItemRoute>!
    var delegate: MockCipherItemOperationDelegate!
    var errorReporter: MockErrorReporter!
    var pasteboardService: MockPasteboardService!
    var subject: ViewItemProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator<VaultItemRoute>()
        delegate = MockCipherItemOperationDelegate()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()
        vaultRepository = MockVaultRepository()
        let services = ServiceContainer.withMocks(
            errorReporter: errorReporter,
            pasteboardService: pasteboardService,
            vaultRepository: vaultRepository
        )
        subject = ViewItemProcessor(
            coordinator: coordinator,
            delegate: delegate,
            itemId: "id",
            services: services,
            state: ViewItemState()
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        errorReporter = nil
        pasteboardService = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `didMoveCipher(_:to:)` displays a toast after the cipher is moved to the organization.
    func test_didMoveCipher() {
        subject.didMoveCipher(.fixture(name: "Bitwarden Password"), to: .organization(id: "1", name: "Organization"))

        waitFor { subject.state.toast != nil }

        XCTAssertEqual(
            subject.state.toast?.text,
            Localizations.movedItemToOrg("Bitwarden Password", "Organization")
        )
    }

    /// `perform(_:)` with `.appeared` starts listening for updates with the vault repository.
    func test_perform_appeared() {
        let cipherItem = CipherView.fixture(
            id: "id",
            login: LoginView(
                username: "username",
                password: "password",
                passwordRevisionDate: Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil
            ),
            name: "Name",
            notes: "Notes",
            viewPassword: true
        )
        vaultRepository.cipherDetailsSubject.send(cipherItem)

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.loadingState != .loading)
        task.cancel()

        let expectedState = CipherItemState(existing: cipherItem, hasPremium: true)!

        XCTAssertEqual(subject.state.loadingState, .data(expectedState))
        XCTAssertFalse(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.appeared` starts listening for updates with the vault repository.
    func test_perform_appeared_invalidFixture() {
        let cipherItem = CipherView.fixture()
        vaultRepository.cipherDetailsSubject.send(cipherItem)

        let task = Task {
            await subject.perform(.appeared)
        }
        waitFor(vaultRepository.doesActiveAccountHavePremiumCalled)
        task.cancel()

        XCTAssertEqual(
            subject.state.loadingState,
            .loading
        )
        XCTAssertFalse(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.appeared` observe the premium status of a user.
    func test_perform_appeared_nonPremium() {
        let cipherItem = CipherView.loginFixture(
            id: "id"
        )
        vaultRepository.hasPremiumResult = .success(false)
        vaultRepository.cipherDetailsSubject.send(cipherItem)

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.loadingState != .loading)
        task.cancel()

        let expectedState = CipherItemState(existing: cipherItem, hasPremium: false)!

        XCTAssertEqual(subject.state.loadingState, .data(expectedState))
        XCTAssertFalse(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.appeared` observe the premium status of a user.
    func test_perform_appeared_unknownPremium() {
        let cipherItem = CipherView.loginFixture(
            id: "id"
        )
        struct TestError: Error, Equatable {}
        vaultRepository.hasPremiumResult = .failure(TestError())
        vaultRepository.cipherDetailsSubject.send(cipherItem)

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.loadingState != .loading)
        task.cancel()

        let expectedState = CipherItemState(existing: cipherItem, hasPremium: false)!

        XCTAssertEqual(subject.state.loadingState, .data(expectedState))
        XCTAssertFalse(vaultRepository.fetchSyncCalled)
    }

    /// `receive` with `.cardItemAction` while loading logs an error.
    func test_receive_cardItemAction_impossible_loading() throws {
        subject.state.loadingState = .loading
        subject.receive(.cardItemAction(.toggleCodeVisibilityChanged(true)))
        XCTAssertEqual(
            errorReporter.errors.first as? ViewItemProcessor.ActionError,
            ViewItemProcessor.ActionError.dataNotLoaded("Cannot handle card action without loaded data")
        )
    }

    /// `receive` with `.cardItemAction` throws if the cipher is not of card type.
    func test_receive_cardItemAction_impossible_nonCard() throws {
        let cipherView = CipherView.fixture(
            id: "123",
            login: nil,
            name: "name",
            revisionDate: Date(),
            type: .login
        )
        let cipherState = CipherItemState(existing: cipherView, hasPremium: true)!
        subject.state.loadingState = .data(cipherState)
        subject.receive(.cardItemAction(.toggleCodeVisibilityChanged(true)))
        XCTAssertEqual(
            errorReporter.errors.first as? ViewItemProcessor.ActionError,
            ViewItemProcessor.ActionError.nonCardTypeToggle("Cannot handle card action on non-card type")
        )
    }

    /// `receive` with `.passwordVisibilityPressed` with a login state toggles the value
    /// for `isPasswordVisible`.
    func test_receive_cardItemAction_code() throws {
        let cipherView = CipherView.cardFixture(id: "123")
        var cipherState = CipherItemState(existing: cipherView, hasPremium: true)!
        subject.state.loadingState = .data(cipherState)
        subject.receive(.cardItemAction(.toggleCodeVisibilityChanged(true)))

        cipherState.cardItemState.isCodeVisible = true
        XCTAssertEqual(subject.state.loadingState, .data(cipherState))
    }

    /// `receive` with `.passwordVisibilityPressed` with a login state toggles the value
    /// for `isPasswordVisible`.
    func test_receive_cardItemAction_number() throws {
        let cipherView = CipherView.cardFixture(id: "123")
        var cipherState = CipherItemState(existing: cipherView, hasPremium: true)!
        subject.state.loadingState = .data(cipherState)
        subject.receive(.cardItemAction(.toggleNumberVisibilityChanged(true)))

        cipherState.cardItemState.isNumberVisible = true
        XCTAssertEqual(subject.state.loadingState, .data(cipherState))
    }

    /// `receive` with `.checkPasswordPressed` checks the password with the HIBP service.
    func test_receive_checkPasswordPressed() {
        subject.receive(.checkPasswordPressed)
        // TODO: BIT-1130 Assertion for check password service call
    }

    /// `receive` with `.copyPressed` copies the value with the pasteboard service.
    func test_receive_copyPressed() {
        subject.receive(.copyPressed(value: "value"))
        XCTAssertEqual(pasteboardService.copiedString, "value")
    }

    /// `receive` with `.customFieldVisibilityPressed()` toggles custom field visibility.
    func test_receive_customFieldVisiblePressed_withValidField() throws {
        let customField1 = CustomFieldState(
            isPasswordVisible: false,
            linkedIdType: nil,
            name: "name 1",
            type: .hidden,
            value: "value 1"
        )
        let customField2 = CustomFieldState(
            isPasswordVisible: false,
            linkedIdType: nil,
            name: "name 2",
            type: .hidden,
            value: "value 2"
        )
        let customField3 = CustomFieldState(
            isPasswordVisible: false,
            linkedIdType: nil,
            name: "name 3",
            type: .hidden,
            value: "value 3"
        )
        var cipherState = CipherItemState(
            existing: CipherView.loginFixture(),
            hasPremium: true
        )!
        cipherState.customFields = [
            customField1,
            customField2,
            customField3,
        ]
        let state = ViewItemState(
            loadingState: .data(cipherState)
        )
        subject.state = state

        subject.receive(.customFieldVisibilityPressed(customField2))
        let newLoadingState = try XCTUnwrap(subject.state.loadingState.wrappedData)
        guard let loadingState = newLoadingState.viewState else {
            XCTFail("ViewItemState has incorrect value: \(newLoadingState)")
            return
        }
        let customFields = loadingState.customFields
        XCTAssertEqual(customFields.count, 3)
        XCTAssertFalse(customFields[0].isPasswordVisible)
        XCTAssertTrue(customFields[1].isPasswordVisible)
        XCTAssertFalse(customFields[2].isPasswordVisible)
    }

    /// `receive` with `.customFieldVisibilityPressed()` while loading logs an error.
    func test_receive_customFieldVisiblePressed_impossible() throws {
        let customField = CustomFieldState(
            isPasswordVisible: false,
            linkedIdType: nil,
            name: "name 2",
            type: .hidden,
            value: "value 2"
        )
        subject.state.loadingState = .loading
        subject.receive(.customFieldVisibilityPressed(customField))
        XCTAssertEqual(
            errorReporter.errors.first as? ViewItemProcessor.ActionError,
            ViewItemProcessor.ActionError
                .dataNotLoaded("Cannot toggle password for non-loaded item.")
        )
    }

    /// `receive` with `.dismissPressed` navigates to the `.dismiss` route.
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)
        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }

    /// `perform(_:)` with `.deletePressed` presents the confirmation alert before delete the item and displays
    /// generic error alert if soft deleting fails.
    func test_perform_deletePressed_genericError() async throws {
        let cipherState = CipherItemState(
            existing: CipherView.loginFixture(id: "123"),
            hasPremium: false
        )!

        let state = ViewItemState(
            loadingState: .data(cipherState)
        )
        subject.state = state
        struct TestError: Error, Equatable {}
        vaultRepository.softDeleteCipherResult = .failure(TestError())
        await subject.perform(.deletePressed)
        // Ensure the alert is shown.
        var alert = coordinator.alertShown.last
        XCTAssertEqual(alert, .deleteCipherConfirmation {})

        // Tap the "Yes" button on the alert.
        let action = try XCTUnwrap(alert?.alertActions.first(where: { $0.title == Localizations.yes }))
        await action.handler?(action, [])

        // Ensure the generic error alert is displayed.
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(
            alert,
            .networkResponseError(TestError())
        )
        XCTAssertEqual(errorReporter.errors.first as? TestError, TestError())
    }

    /// `perform(_:)` with `.deletePressed` presents the confirmation alert before delete the item and displays
    /// toast if soft deleting succeeds.
    func test_perform_deletePressed_success() async throws {
        let cipherState = CipherItemState(
            existing: CipherView.loginFixture(id: "123"),
            hasPremium: false
        )!

        let state = ViewItemState(
            loadingState: .data(cipherState)
        )
        subject.state = state
        vaultRepository.softDeleteCipherResult = .success(())
        await subject.perform(.deletePressed)
        // Ensure the alert is shown.
        let alert = coordinator.alertShown.last
        XCTAssertEqual(alert, .deleteCipherConfirmation {})

        // Tap the "Yes" button on the alert.
        let action = try XCTUnwrap(alert?.alertActions.first(where: { $0.title == Localizations.yes }))
        await action.handler?(action, [])

        XCTAssertNil(errorReporter.errors.first)
        // Ensure the cipher is deleted and the view is dismissed.
        XCTAssertEqual(vaultRepository.softDeletedCipher.last?.id, "123")
        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = coordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()
        XCTAssertTrue(delegate.itemDeletedCalled)
    }

    /// `receive` with `.editPressed` has no change when the state is loading.
    func test_receive_editPressed_loading() {
        subject.receive(.editPressed)
        XCTAssertEqual(coordinator.routes, [])
    }

    /// `receive` with `.editPressed`with data navigates to the edit item route.
    func test_receive_editPressed_data() {
        let cipherView = CipherView.fixture(
            id: "123",
            login: BitwardenSdk.LoginView(
                username: nil,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil
            ),
            name: "name",
            revisionDate: Date()
        )
        let loginState = CipherItemState(existing: cipherView, hasPremium: true)!
        subject.state.loadingState = .data(loginState)
        subject.receive(.editPressed)
        XCTAssertEqual(coordinator.routes, [.editItem(cipher: cipherView)])
    }

    /// `receive(_:)` with `.morePressed(.moveToOrganization)` navigates the user to the move to
    /// organization view.
    func test_receive_morePressed_moveToOrganization() throws {
        let cipher = CipherView.fixture(id: "1")
        subject.state.loadingState = try .data(XCTUnwrap(CipherItemState(existing: cipher, hasPremium: false)))

        subject.receive(.morePressed(.moveToOrganization))

        XCTAssertEqual(coordinator.routes.last, .moveToOrganization(cipher))
        XCTAssertTrue(coordinator.contexts.last as? ViewItemProcessor === subject)
    }

    /// `receive` with `.passwordVisibilityPressed` while loading logs an error.
    func test_receive_passwordVisibilityPressed_impossible_loading() throws {
        subject.state.loadingState = .loading
        subject.receive(.passwordVisibilityPressed)
        XCTAssertEqual(
            errorReporter.errors.first as? ViewItemProcessor.ActionError,
            ViewItemProcessor.ActionError
                .dataNotLoaded("Cannot toggle password for non-loaded item.")
        )
    }

    /// `receive` with `.passwordVisibilityPressed` while loading logs an error.
    func test_receive_passwordVisibilityPressed_impossible_nonLogin() throws {
        let cipherView = CipherView.fixture(
            id: "123",
            login: nil,
            name: "name",
            revisionDate: Date(),
            type: .card
        )
        let cipherState = CipherItemState(existing: cipherView, hasPremium: true)!
        subject.state.loadingState = .data(cipherState)
        subject.receive(.passwordVisibilityPressed)
        XCTAssertEqual(
            errorReporter.errors.first as? ViewItemProcessor.ActionError,
            ViewItemProcessor.ActionError
                .nonLoginPasswordToggle("Cannot toggle password for non-login item.")
        )
    }

    /// `receive` with `.passwordVisibilityPressed` with a login state toggles the value
    /// for `isPasswordVisible`.
    func test_receive_passwordVisibilityPressed_withLoginState() {
        let cipherView = CipherView.fixture(
            id: "123",
            login: BitwardenSdk.LoginView(
                username: nil,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil
            ),
            name: "name",
            revisionDate: Date()
        )
        var cipherState = CipherItemState(existing: cipherView, hasPremium: true)!
        subject.state.loadingState = .data(cipherState)
        subject.receive(.passwordVisibilityPressed)

        cipherState.loginState.isPasswordVisible = true
        XCTAssertEqual(subject.state.loadingState, .data(cipherState))
    }

    /// `receive` with `.passwordVisibilityPressed` with a login state toggles the value
    /// for `isPasswordVisible`.
    func test_receive_passwordVisibilityPressed_withLoginState_withMasterPasswordReprompt() throws {
        let cipherView = CipherView.fixture(
            id: "123",
            login: BitwardenSdk.LoginView(
                username: nil,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil
            ),
            name: "name",
            reprompt: .password,
            revisionDate: Date()
        )
        let loginState = CipherItemState(existing: cipherView, hasPremium: true)!
        subject.state.loadingState = .data(loginState)
        subject.receive(.passwordVisibilityPressed)

        XCTAssertEqual(try coordinator.unwrapLastRouteAsAlert(), .masterPasswordPrompt(completion: { _ in }))
    }

    /// `receive(_:)` with `.toastShown` with a value updates the state correctly.
    func test_receive_toastShown_withValue() {
        let toast = Toast(text: "123")
        subject.receive(.toastShown(toast))

        XCTAssertEqual(subject.state.toast, toast)
    }

    /// Tapping the "Submit" button in the master password reprompt alert validates the entered
    /// password and completes the action.
    func test_masterPasswordReprompt_submitButtonPressed() async throws {
        let cipherView = CipherView.fixture(
            id: "123",
            login: BitwardenSdk.LoginView(
                username: nil,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil
            ),
            name: "name",
            reprompt: .password,
            revisionDate: Date()
        )
        var cipherState = CipherItemState(existing: cipherView, hasPremium: true)!
        subject.state.loadingState = .data(cipherState)
        subject.receive(.passwordVisibilityPressed)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertNotNil(alert.alertTextFields.first)
        let action = try XCTUnwrap(alert.alertActions.first(where: { $0.title == Localizations.submit }))
        await action.handler?(action, [AlertTextField(id: "password", text: "password1234")])

        XCTAssertEqual(vaultRepository.validatePasswordPasswords, ["password1234"])

        cipherState.loginState.isPasswordVisible = true
        XCTAssertEqual(subject.state.loadingState, .data(cipherState))
        XCTAssertTrue(subject.state.hasVerifiedMasterPassword)
    }

    /// If validation the user's password fails, an error is logged.
    func test_masterPasswordReprompt_submitButtonPressed_error() async throws {
        struct ValidatePasswordError: Error {}
        vaultRepository.validatePasswordResult = .failure(ValidatePasswordError())

        let cipherView = CipherView.fixture(id: "1", reprompt: .password)
        let cipherState = CipherItemState(existing: cipherView, hasPremium: true)!
        subject.state.loadingState = .data(cipherState)
        subject.receive(.passwordVisibilityPressed)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertNotNil(alert.alertTextFields.first)
        let action = try XCTUnwrap(alert.alertActions.first(where: { $0.title == Localizations.submit }))
        await action.handler?(action, [AlertTextField(id: "password", text: "password1234")])

        XCTAssertEqual(vaultRepository.validatePasswordPasswords, ["password1234"])
        XCTAssertFalse(subject.state.hasVerifiedMasterPassword)
        XCTAssertTrue(errorReporter.errors.last is ValidatePasswordError)
    }

    /// If the user's password validation fails, an invalid password alert is presented.
    func test_masterPasswordReprompt_submitButtonPressed_invalidPassword() async throws {
        vaultRepository.validatePasswordResult = .success(false)

        let cipherView = CipherView.fixture(id: "1", reprompt: .password)
        let cipherState = CipherItemState(existing: cipherView, hasPremium: true)!
        subject.state.loadingState = .data(cipherState)
        subject.receive(.passwordVisibilityPressed)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertNotNil(alert.alertTextFields.first)
        let action = try XCTUnwrap(alert.alertActions.first(where: { $0.title == Localizations.submit }))
        await action.handler?(action, [AlertTextField(id: "password", text: "password1234")])

        XCTAssertEqual(vaultRepository.validatePasswordPasswords, ["password1234"])
        XCTAssertFalse(subject.state.hasVerifiedMasterPassword)

        let invalidPasswordAlert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(invalidPasswordAlert, .defaultAlert(title: Localizations.invalidMasterPassword))
    }
} // swiftlint:disable:this file_length
