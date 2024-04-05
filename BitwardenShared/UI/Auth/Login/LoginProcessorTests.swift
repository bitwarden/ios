import AuthenticationServices
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - LoginProcessorTests

class LoginProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var authRepository: MockAuthRepository!
    var authService: MockAuthService!
    var captchaService: MockCaptchaService!
    var client: MockHTTPClient!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var subject: LoginProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        authRepository = MockAuthRepository()
        authService = MockAuthService()
        captchaService = MockCaptchaService()
        client = MockHTTPClient()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()

        let account = Account.fixture()
        authRepository.accountForItemResult = .success(account)

        subject = LoginProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                appSettingsStore: appSettingsStore,
                authRepository: authRepository,
                authService: authService,
                captchaService: captchaService,
                errorReporter: errorReporter,
                httpClient: client
            ),
            state: LoginState()
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        authRepository = nil
        authService = nil
        captchaService = nil
        client = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `captchaCompleted()` makes the login requests again, this time with a captcha token.
    func test_captchaCompleted() {
        subject.state.masterPassword = "Test"
        subject.captchaCompleted(token: "token")
        authRepository.unlockWithPasswordResult = .success(())
        authRepository.activeAccount = .fixture()
        waitFor(!coordinator.events.isEmpty)

        XCTAssertEqual(authService.loginWithMasterPasswordCaptchaToken, "token")

        XCTAssertEqual(coordinator.events.last, .didCompleteAuth)
    }

    /// `captchaErrored(error:)` records an error.
    func test_captchaErrored() {
        subject.captchaErrored(error: BitwardenTestError.example)

        waitFor(!coordinator.alertShown.isEmpty)
        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(BitwardenTestError.example))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `captchaErrored(error:)` doesn't record an error if the captcha flow was cancelled.
    func test_captchaErrored_cancelled() {
        let error = NSError(domain: "", code: ASWebAuthenticationSessionError.canceledLogin.rawValue)
        subject.captchaErrored(error: error)
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `perform(_:)` with `.appeared` and an error occurs does not update the login with button visibility.
    func test_perform_appeared_failure() async throws {
        subject.state.isLoginWithDeviceVisible = false
        client.results = [
            .httpFailure(BitwardenTestError.example),
        ]
        await subject.perform(.appeared)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [.init(title: Localizations.loading)])
        XCTAssertFalse(subject.state.isLoginWithDeviceVisible)
        // TODO: BIT-709 Add assertion for error state.
    }

    /// `perform(_:)` with `.appeared` and a true result shows the login with device button.
    func test_perform_appeared_success_true() async throws {
        client.results = [
            .httpSuccess(testData: .knownDeviceTrue),
        ]
        await subject.perform(.appeared)

        XCTAssertTrue(subject.state.isLoginWithDeviceVisible)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [.init(title: Localizations.loading)])
    }

    /// `perform(_:)` with `.appeared` and a false result hides the login with device button.
    func test_perform_appeared_success_false() async throws {
        client.results = [
            .httpSuccess(testData: .knownDeviceFalse),
        ]
        await subject.perform(.appeared)

        XCTAssertFalse(subject.state.isLoginWithDeviceVisible)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [.init(title: Localizations.loading)])
    }

    /// `perform(_:)` with `.appeared` twice in a row only makes the API call once.
    func test_perform_appeared_twice() async throws {
        client.results = [
            .httpSuccess(testData: .knownDeviceTrue),
            .httpSuccess(testData: .knownDeviceTrue),
        ]
        await subject.perform(.appeared)
        await subject.perform(.appeared)

        XCTAssertTrue(subject.state.isLoginWithDeviceVisible)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [.init(title: Localizations.loading)])
    }

    /// `perform(_:)` with `.loginWithMasterPasswordPressed` logs the user in with the provided master password.
    func test_perform_loginWithMasterPasswordPressed_success() async throws {
        subject.state.username = "email@example.com"
        subject.state.masterPassword = "Password1234!"

        authRepository.unlockWithPasswordResult = .success(())
        authRepository.activeAccount = .fixture()

        await subject.perform(.loginWithMasterPasswordPressed)

        XCTAssertEqual(authService.loginWithMasterPasswordUsername, "email@example.com")
        XCTAssertEqual(authService.loginWithMasterPasswordPassword, "Password1234!")
        XCTAssertNil(authService.loginWithMasterPasswordCaptchaToken)

        XCTAssertEqual(coordinator.events.last, .didCompleteAuth)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [.init(title: Localizations.loggingIn)])

        XCTAssertEqual(authRepository.unlockVaultPassword, "Password1234!")
    }

    /// `perform(_:)` with `.loginWithMasterPasswordPressed` logs the user in with the provided master password,
    /// presents update master password view if user's password needs to be updated.
    func test_perform_loginWithMasterPasswordPressed_updateMasterPassword() async throws {
        var account = Account.fixture()
        account.profile.forcePasswordResetReason = .adminForcePasswordReset
        authRepository.accountForItemResult = .success(account)
        subject.state.username = "email@example.com"
        subject.state.masterPassword = "Password1234!"
        authRepository.unlockWithPasswordResult = .success(())
        authRepository.activeAccount = account
        authService.requirePasswordChangeResult = .success(true)
        await subject.perform(.loginWithMasterPasswordPressed)

        XCTAssertEqual(authService.loginWithMasterPasswordUsername, "email@example.com")
        XCTAssertEqual(authService.loginWithMasterPasswordPassword, "Password1234!")
        XCTAssertNil(authService.loginWithMasterPasswordCaptchaToken)

        XCTAssertEqual(coordinator.events.last, .didCompleteAuth)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [.init(title: Localizations.loggingIn)])

        XCTAssertEqual(authRepository.unlockVaultPassword, "Password1234!")
    }

    /// `perform(_:)` with `.loginWithMasterPasswordPressed` and a captcha error occurs navigates to the `.captcha`
    /// route.
    func test_perform_loginWithMasterPasswordPressed_captchaError() async {
        subject.state.masterPassword = "Test"
        authService.loginWithMasterPasswordResult = .failure(
            IdentityTokenRequestError.captchaRequired(hCaptchaSiteCode: "token")
        )

        await subject.perform(.loginWithMasterPasswordPressed)

        XCTAssertEqual(captchaService.callbackUrlSchemeGets, 1)
        XCTAssertEqual(captchaService.generateCaptchaSiteKey, "token")

        XCTAssertEqual(coordinator.routes.last, .captcha(url: .example, callbackUrlScheme: "callback"))
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [.init(title: Localizations.loggingIn)])
    }

    /// `perform(_:)` with `.loginWithMasterPasswordPressed` and a captcha flow error records the error.
    func test_perform_loginWithMasterPasswordPressed_captchaFlowError() async {
        subject.state.masterPassword = "Test"
        authService.loginWithMasterPasswordResult = .failure(
            IdentityTokenRequestError.captchaRequired(hCaptchaSiteCode: "token")
        )
        captchaService.generateCaptchaUrlResult = .failure(BitwardenTestError.example)

        await subject.perform(.loginWithMasterPasswordPressed)

        XCTAssertEqual(authService.loginWithMasterPasswordPassword, "Test")
        XCTAssertEqual(captchaService.generateCaptchaSiteKey, "token")

        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(BitwardenTestError.example))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.loginWithMasterPasswordPressed` records non captcha errors.
    func test_perform_loginWithMasterPasswordPressed_error() async throws {
        subject.state.masterPassword = "Test"
        authService.loginWithMasterPasswordResult = .failure(BitwardenTestError.example)

        await subject.perform(.loginWithMasterPasswordPressed)

        XCTAssertEqual(authService.loginWithMasterPasswordPassword, "Test")

        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(BitwardenTestError.example))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.loginWithMasterPasswordPressed` shows an alert for empty login text.
    func test_perform_loginWithMasterPasswordPressed_invalidInput() async throws {
        await subject.perform(.loginWithMasterPasswordPressed)
        XCTAssertEqual(
            coordinator.alertShown.last,
            .inputValidationAlert(error: InputValidationError(
                message: Localizations.validationFieldRequired(Localizations.masterPassword)
            ))
        )
    }

    /// `perform(_:)` with `.loginWithMasterPasswordPressed` navigates to the `.twoFactor` route
    /// if two-factor authentication is required.
    func test_perform_loginWithMasterPasswordPressed_twoFactorError() async {
        subject.state.masterPassword = "Test"
        authService.loginWithMasterPasswordResult = .failure(
            IdentityTokenRequestError.twoFactorRequired(AuthMethodsData(), nil, nil)
        )

        await subject.perform(.loginWithMasterPasswordPressed)

        XCTAssertEqual(coordinator.routes.last, .twoFactor("", .password("Test"), AuthMethodsData(), nil))
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [.init(title: Localizations.loggingIn)])
    }

    /// `receive(_:)` with `.enterpriseSingleSignOnPressed` navigates to the enterprise single sign-on screen.
    func test_receive_enterpriseSingleSignOnPressed() {
        subject.state.username = "test@example.com"
        subject.receive(.enterpriseSingleSignOnPressed)
        XCTAssertEqual(coordinator.routes.last, .enterpriseSingleSignOn(email: "test@example.com"))
    }

    /// `receive(_:)` with `.getMasterPasswordHintPressed` navigates to the master password hint screen.
    func test_receive_getMasterPasswordHintPressed() {
        subject.state.username = "test@example.com"
        subject.receive(.getMasterPasswordHintPressed)
        XCTAssertEqual(coordinator.routes.last, .masterPasswordHint(username: "test@example.com"))
    }

    /// `receive(_:)` with `.loginWithDevicePressed` navigates to the login with device screen.
    func test_receive_loginWithDevicePressed() {
        subject.state.username = "example@email.com"
        subject.receive(.loginWithDevicePressed)
        XCTAssertEqual(coordinator.routes.last, .loginWithDevice(
            email: "example@email.com",
            authRequestType: AuthRequestType.authenticateAndUnlock
        ))
    }

    /// `receive(_:)` with `.masterPasswordChanged` updates the state to reflect the changes.
    func test_receive_masterPasswordChanged() {
        subject.state.masterPassword = ""

        subject.receive(.masterPasswordChanged("password"))
        XCTAssertEqual(subject.state.masterPassword, "password")
    }

    /// `receive(_:)` with `.notYouPressed` navigates to the landing screen.
    func test_receive_notYouPressed() {
        subject.receive(.notYouPressed)
        XCTAssertEqual(coordinator.routes.last, .landing)
    }

    /// `receive(_:)` with `.revealMasterPasswordFieldPressed` updates the state to reflect the changes.
    func test_receive_revealMasterPasswordFieldPressed() {
        subject.state.isMasterPasswordRevealed = false
        subject.receive(.revealMasterPasswordFieldPressed(true))
        XCTAssertTrue(subject.state.isMasterPasswordRevealed)

        subject.receive(.revealMasterPasswordFieldPressed(false))
        XCTAssertFalse(subject.state.isMasterPasswordRevealed)
    }
}
