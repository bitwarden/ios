import XCTest

@testable import BitwardenShared

class DeleteAccountProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: DeleteAccountProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        coordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        subject = DeleteAccountProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                errorReporter: errorReporter,
                stateService: stateService
            ),
            state: DeleteAccountState()
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        coordinator = nil
        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// Receiving `.dismiss` dismisses the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// Perform with `.deleteAccount` presents the master password prompt alert.
    @MainActor
    func test_perform_deleteAccount() async {
        await subject.perform(.deleteAccount)

        XCTAssertEqual(coordinator.alertShown.last, .masterPasswordPrompt(completion: { _ in }))
    }

    /// Perform with `.deleteAccount` presents the master password prompt alert. If there's an
    /// error with deleting the account, an alert is shown and the error is logged.
    @MainActor
    func test_perform_deleteAccount_error() async throws {
        authRepository.deleteAccountResult = .failure(URLError(.timedOut))

        await subject.perform(.deleteAccount)

        let passwordAlert = try XCTUnwrap(coordinator.alertShown.last)
        try passwordAlert.setText("password", forTextFieldWithId: "password")
        try await passwordAlert.tapAction(title: Localizations.submit)

        XCTAssertTrue(authRepository.deleteAccountCalled)

        let errorAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(errorAlert, .networkResponseError(URLError(.timedOut)))
        XCTAssertEqual(errorReporter.errors as? [URLError], [URLError(.timedOut)])

        authRepository.deleteAccountCalled = false
        errorReporter.errors.removeAll()

        authRepository.deleteAccountResult = .success(())
        try await errorAlert.tapAction(title: Localizations.tryAgain)
        XCTAssertTrue(authRepository.deleteAccountCalled)
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// Perform with `.deleteAccount` presents the master password prompt alert. If there's an
    /// invalid password error with deleting the account, an alert is shown.
    @MainActor
    func test_perform_deleteAccount_serverError() async throws {
        authRepository.deleteAccountResult = .failure(
            ServerError.error(
                errorResponse: ErrorResponseModel(
                    validationErrors: nil,
                    message: ""
                )
            )
        )

        await subject.perform(.deleteAccount)

        var alert = try XCTUnwrap(coordinator.alertShown.last)
        try alert.setText("password", forTextFieldWithId: "password")
        try await alert.tapAction(title: Localizations.submit)

        XCTAssertTrue(authRepository.deleteAccountCalled)

        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .defaultAlert(title: Localizations.invalidMasterPassword))
    }

    /// Perform with `.deleteAccount` presents the master password prompt alert.
    /// Pressing submit on the alert deletes the user's account.
    @MainActor
    func test_perform_deleteAccount_submitPressed_noOtherAccounts() async throws {
        let account = Account.fixture(profile: Account.AccountProfile.fixture(userId: "1"))

        await stateService.addAccount(account)
        await subject.perform(.deleteAccount)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try alert.setText("password", forTextFieldWithId: "password")
        try await alert.tapAction(title: Localizations.submit)

        await assertAsyncThrows {
            _ = try await stateService.getAccounts()
            XCTAssertEqual(errorReporter.errors as? [StateServiceError], [StateServiceError.noAccounts])
        }
    }

    /// Perform with `.deleteAccount` presents the master password prompt alert.
    /// Pressing submit on the alert deletes the user's account.
    @MainActor
    func test_perform_deleteAccount_submitPressed_otherAccounts() async throws {
        let account = Account.fixture(profile: Account.AccountProfile.fixture(userId: "1"))
        let account2 = Account.fixture(profile: Account.AccountProfile.fixture(userId: "2"))

        await stateService.addAccount(account)
        await stateService.addAccount(account2)
        await subject.perform(.deleteAccount)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try alert.setText("password", forTextFieldWithId: "password")
        try await alert.tapAction(title: Localizations.submit)

        XCTAssertEqual(stateService.activeAccount, account2)
    }

    /// Perform with `.deleteAccount` presents the OTP code verification alert for users without a
    /// master password. Pressing submit on the alert deletes the user's account.
    @MainActor
    func test_perform_deleteAccount_submitPressed_noMasterPassword() async throws {
        authRepository.hasMasterPasswordResult = .success(false)
        stateService.activeAccount = Account.fixtureWithTdeNoPassword()

        await subject.perform(.deleteAccount)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .verificationCodePrompt { _ in })
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.sendingCode)])
        XCTAssertTrue(authRepository.requestOtpCalled)
        coordinator.loadingOverlaysShown.removeAll()

        try alert.setText("otp", forTextFieldWithId: "otp")
        try await alert.tapAction(title: Localizations.submit)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(
            coordinator.loadingOverlaysShown,
            [LoadingOverlayState(title: Localizations.deletingYourAccount)]
        )
        XCTAssertTrue(authRepository.deleteAccountCalled)
    }

    /// Perform with `.deleteAccount` presents the OTP code verification alert for users without a
    /// master password. If an error occurs it's logged and an alert is shown.
    @MainActor
    func test_perform_deleteAccount_submitPressed_noMasterPassword_error() async throws {
        authRepository.hasMasterPasswordResult = .success(false)
        authRepository.requestOtpResult = .failure(BitwardenTestError.example)
        stateService.activeAccount = Account.fixtureWithTdeNoPassword()

        await subject.perform(.deleteAccount)

        XCTAssertEqual(coordinator.alertShown, [.networkResponseError(BitwardenTestError.example)])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// Perform with `.deleteAccount` presents the OTP code verification alert. If there's an
    /// invalid verification error error, an alert is shown.
    @MainActor
    func test_perform_deleteAccount_noMasterPassword_serverError() async throws {
        authRepository.deleteAccountResult = .failure(
            ServerError.error(
                errorResponse: ErrorResponseModel(
                    validationErrors: nil,
                    message: ""
                )
            )
        )
        authRepository.hasMasterPasswordResult = .success(false)

        await subject.perform(.deleteAccount)

        var alert = try XCTUnwrap(coordinator.alertShown.last)
        try alert.setText("otp", forTextFieldWithId: "otp")
        try await alert.tapAction(title: Localizations.submit)

        XCTAssertTrue(authRepository.deleteAccountCalled)

        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .defaultAlert(title: Localizations.invalidVerificationCode))
    }

    /// `perform(_:)` with `.loadData` loads the initial data for the view.
    @MainActor
    func test_perform_loadData() async {
        stateService.activeAccount = .fixture()
        authRepository.isUserManagedByOrganizationResult = .success(true)
        await subject.perform(.loadData)

        XCTAssertTrue(subject.state.shouldPreventUserFromDeletingAccount)

        authRepository.isUserManagedByOrganizationResult = .success(false)
        await subject.perform(.loadData)

        XCTAssertFalse(subject.state.shouldPreventUserFromDeletingAccount)
    }

    /// `perform(_:)` with `.loadData` loads the initial data for the view. If an error occurs it's logged
    ///  and an alert is shown.
    @MainActor
    func test_perform_loadData_error() async throws {
        stateService.activeAccount = .fixture()
        authRepository.isUserManagedByOrganizationResult = .failure(BitwardenTestError.example)

        await subject.perform(.loadData)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.alertActions.count, 1)

        try await alert.tapAction(title: Localizations.ok)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }
}
