import AuthenticationServices
import BitwardenSdk
import XCTest

// swiftlint:disable file_length

@testable import BitwardenShared

// MARK: - TwoFactorAuthProcessorTests

class TwoFactorAuthProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var authRepository: MockAuthRepository!
    var authService: MockAuthService!
    var captchaService: MockCaptchaService!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var nfcReaderService: MockNFCReaderService!
    var subject: TwoFactorAuthProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        authRepository = MockAuthRepository()
        authService = MockAuthService()
        captchaService = MockCaptchaService()
        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        nfcReaderService = MockNFCReaderService()

        subject = TwoFactorAuthProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                appSettingsStore: appSettingsStore,
                authRepository: authRepository,
                authService: authService,
                captchaService: captchaService,
                environmentService: environmentService,
                errorReporter: errorReporter,
                nfcReaderService: nfcReaderService
            ),
            state: TwoFactorAuthState()
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        authRepository = nil
        authService = nil
        captchaService = nil
        coordinator = nil
        environmentService = nil
        errorReporter = nil
        nfcReaderService = nil
        subject = nil
    }

    // MARK: Tests

    /// `captchaCompleted()` makes the login requests again, this time with a captcha token.
    func test_captchaCompleted() {
        subject.state.verificationCode = "Test"
        subject.captchaCompleted(token: "token")
        waitFor(!coordinator.routes.isEmpty)

        XCTAssertEqual(authService.loginWithTwoFactorCodeCaptchaToken, "token")

        XCTAssertEqual(coordinator.routes.last, .dismiss)
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

    /// `init` sets up the state correctly.
    func test_init() {
        let authMethodsData = AuthMethodsData.fixture()
        let state = TwoFactorAuthState(authMethodsData: authMethodsData)
        subject = TwoFactorAuthProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter
            ),
            state: state
        )

        XCTAssertEqual(subject.state.availableAuthMethods, [.authenticatorApp, .email, .yubiKey, .recoveryCode])
        XCTAssertEqual(subject.state.displayEmail, "sh***@example.com")
    }

    /// A `didComplete` call triggers the `.receivedDuoToken` effect.
    func test_duoAuthenticationFlowDelegate_didComplete() {
        subject.state.authMethod = .duo
        subject.state.verificationCode = ""
        subject.state.unlockMethod = .password("duo token")
        authService.loginWithTwoFactorCodeResult = .success(.fixtureAccountLogin())

        let task = Task {
            subject.didComplete(code: "1234")
        }
        waitFor(!coordinator.events.isEmpty)
        task.cancel()

        XCTAssertEqual(subject.state.verificationCode, "1234")
        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
        XCTAssertEqual(authRepository.unlockVaultPassword, "duo token")
    }

    /// A `duoErrored` call presents no alert on cancel.
    func test_duoAuthenticationFlowDelegate_duoErrored_cancel() {
        coordinator.isLoadingOverlayShowing = true
        subject.state.authMethod = .duo

        subject.duoErrored(
            error: ASWebAuthenticationSessionError(ASWebAuthenticationSessionError.canceledLogin)
        )
        waitFor(!coordinator.isLoadingOverlayShowing)

        XCTAssertEqual(coordinator.alertShown, [])
    }

    /// A `duoErrored` call presents an alert on error.
    func test_duoAuthenticationFlowDelegate_duoErrored_decodeFail() {
        subject.state.authMethod = .duo

        subject.duoErrored(error: AuthError.unableToDecodeDuoResponse)
        waitFor(!errorReporter.errors.isEmpty)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(errorReporter.errors.last as? AuthError, .unableToDecodeDuoResponse)
    }

    /// `perform(_:)` with `.beginDuoAuth` does nothing if duo is not configured.
    func test_perform_beginDuoAuth_failure() async {
        subject.state.authMethod = .duo
        subject.state.authMethodsData = AuthMethodsData(
            duo: Duo(
                authUrl: nil,
                host: nil,
                signature: nil
            )
        )
        await subject.perform(.beginDuoAuth)

        XCTAssertEqual(coordinator.routes, [])
    }

    /// `perform(_:)` with `.beginDuoAuth` initates the duo auth flow.
    func test_perform_beginDuoAuth_success() async {
        let expectedURL = URL(string: "bitwarden://expectedURL")!
        subject.state.authMethod = .duo
        subject.state.authMethodsData = AuthMethodsData(
            duo: Duo(
                authUrl: expectedURL.absoluteString,
                host: "",
                signature: ""
            )
        )
        await subject.perform(.beginDuoAuth)

        XCTAssertEqual(coordinator.routes.last, .duoAuthenticationFlow(expectedURL))
    }

    /// `perform(_:)` with `.beginDuoAuth`  does nothing if duo is not the auth method.
    func test_perform_beginDuoAuth_wrongAuthMethod() async {
        let expectedURL = URL(string: "bitwarden://expectedURL")!
        subject.state.authMethod = .authenticatorApp
        subject.state.authMethodsData = AuthMethodsData(
            duo: Duo(
                authUrl: expectedURL.absoluteString,
                host: "",
                signature: ""
            )
        )

        XCTAssertEqual(coordinator.routes, [])
    }

    /// A `webAuthnCompleted` call triggers a login and sets a token
    func test_webAuthnAuthenticationFlowDelegate_didComplete() {
        subject.state.authMethod = .webAuthn
        authService.loginWithTwoFactorCodeResult = .success(.fixtureAccountLogin())
        subject.state.unlockMethod = .password("token")

        let task = Task {
            subject.webAuthnCompleted(token: "1234")
        }
        waitFor(!coordinator.events.isEmpty)
        task.cancel()

        XCTAssertEqual(subject.state.verificationCode, "1234")
        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
        XCTAssertEqual(authRepository.unlockVaultPassword, "token")
    }

    /// A `webAuthnErrored` call presents an alert on error.
    func test_webAuthnAuthenticationFlowDelegate_webAuthnErrored_decodeFail() {
        subject.state.authMethod = .webAuthn

        subject.webAuthnErrored(error: WebAuthnError.unableToDecodeCredential)
        waitFor(!errorReporter.errors.isEmpty)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(errorReporter.errors.last as? WebAuthnError, .unableToDecodeCredential)
    }

    /// `perform(_:)` with `.beginWebAuthn` initates the WebAuthn auth flow.
    func test_perform_beginWebAuthn_success() async throws {
        let testData = AuthMethodsData.fixtureWebAuthn()
        let rpIdExpected = try XCTUnwrap(testData.webAuthn?.rpId)
        let userVerificationPreferenceExpected = try XCTUnwrap(testData.webAuthn?.userVerification)
        let challengeExpected = try XCTUnwrap(
            Data(base64Encoded: XCTUnwrap(testData.webAuthn?.challenge?.urlDecoded()))
        )
        let allowCredentials = try testData.webAuthn?.allowCredentials?.map { credential in
            try XCTUnwrap(Data(base64Encoded: XCTUnwrap(credential.id!.urlDecoded())))
        }
        subject.state.authMethod = .webAuthn
        subject.state.authMethodsData = AuthMethodsData.fixtureWebAuthn()
        await subject.perform(.beginWebAuthn)

        XCTAssertEqual(
            coordinator.routes.last,
            .webAuthn(
                rpid: rpIdExpected,
                challenge: challengeExpected,
                allowCredentialIDs: allowCredentials!,
                userVerificationPreference: userVerificationPreferenceExpected
            )
        )
    }

    /// `perform(_:)` with `.beginWebAuthnAuth`  does nothing if WebAuthn is not configured.
    func test_perform_beginWebAuthn_failure() async {
        subject.state.authMethod = .webAuthn
        subject.state.authMethodsData = AuthMethodsData.fixture()

        XCTAssertEqual(coordinator.routes, [])
    }

    /// `perform(_:)` with `.beginWebAuthnAuth`  does nothing if WebAuthn is not the auth method.
    func test_perform_beginWebAuthn_wrongAuthMethod() async {
        subject.state.authMethod = .authenticatorApp
        subject.state.authMethodsData = AuthMethodsData.fixtureWebAuthn()

        XCTAssertEqual(coordinator.routes, [])
    }

    /// `perform(_:)` with `.continueTapped` navigates to the `.captcha` route if there was a captcha error.
    func test_perform_continueTapped_captchaError() async {
        subject.state.verificationCode = "Test"
        authService.loginWithTwoFactorCodeResult = .failure(
            IdentityTokenRequestError.captchaRequired(hCaptchaSiteCode: "token")
        )

        await subject.perform(.continueTapped)

        XCTAssertEqual(captchaService.callbackUrlSchemeGets, 1)
        XCTAssertEqual(captchaService.generateCaptchaSiteKey, "token")

        XCTAssertEqual(coordinator.routes.last, .captcha(url: .example, callbackUrlScheme: "callback"))
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [.init(title: Localizations.verifying)])
    }

    /// `perform(_:)` with `.continueTapped` and a captcha flow error records the error.
    func test_perform_continueTapped_captchaFlowError() async {
        subject.state.verificationCode = "Test"
        authService.loginWithTwoFactorCodeResult = .failure(
            IdentityTokenRequestError.captchaRequired(hCaptchaSiteCode: "token")
        )
        captchaService.generateCaptchaUrlResult = .failure(BitwardenTestError.example)

        await subject.perform(.continueTapped)

        XCTAssertEqual(authService.loginWithTwoFactorCodeCode, "Test")
        XCTAssertEqual(captchaService.generateCaptchaSiteKey, "token")

        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(BitwardenTestError.example))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.continueTapped` handles any errors correctly.
    func test_perform_continueTapped_error() async {
        subject.state.authMethod = .email
        subject.state.verificationCode = "Test  "
        authService.loginWithTwoFactorCodeResult = .failure(BitwardenTestError.example)

        await subject.perform(.continueTapped)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [.init(title: Localizations.verifying)])
        XCTAssertEqual(authService.loginWithTwoFactorCodeCode, "Test")
        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.invalidVerificationCode
        ))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.continueTapped` shows an alert for empty verification code text.
    func test_perform_continueTapped_invalidInput() async throws {
        await subject.perform(.continueTapped)
        XCTAssertEqual(
            coordinator.alertShown.last,
            .inputValidationAlert(error: InputValidationError(
                message: Localizations.validationFieldRequired(Localizations.verificationCode)
            ))
        )
    }

    /// `perform(_:)` with `.continueTapped` logs in and unlocks the vault successfully when using
    /// a password.
    func test_perform_continueTapped_success() async {
        subject.state.unlockMethod = .password("password123")
        subject.state.verificationCode = "Test"

        await subject.perform(.continueTapped)

        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
        XCTAssertEqual(authRepository.unlockVaultPassword, "password123")
    }

    /// `perform(_:)` with `.continueTapped` logs in and unlocks the vault successfully when using
    /// login with device.
    func test_perform_continueTapped_loginWithDevice_success() async {
        subject.state.unlockMethod = .loginWithDevice(
            key: "KEY",
            masterPasswordHash: "MASTER_PASSWORD_HASH",
            privateKey: "PRIVATE_KEY"
        )
        subject.state.verificationCode = "Test"

        await subject.perform(.continueTapped)

        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
        XCTAssertEqual(authRepository.unlockVaultFromLoginWithDeviceKey, "KEY")
        XCTAssertEqual(authRepository.unlockVaultFromLoginWithDevicePrivateKey, "PRIVATE_KEY")
        XCTAssertEqual(authRepository.unlockVaultFromLoginWithDeviceMasterPasswordHash, "MASTER_PASSWORD_HASH")
    }

    /// `perform(_:)` with `.continueTapped` handles a two-factor error correctly.
    func test_perform_continueTapped_twoFactorError() async {
        subject.state.verificationCode = "Test"
        authService.loginWithTwoFactorCodeResult = .failure(
            IdentityTokenRequestError.twoFactorRequired(.init(), nil, nil)
        )

        await subject.perform(.continueTapped)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.invalidVerificationCode
        ))
    }

    /// `perform(_:)` with `.listenForNFC` starts listening for NFC tags and attempts login if one is read.
    func test_perform_listenForNFC() {
        nfcReaderService.resultSubject.value = "NFC_TAG_VALUE"
        subject.state.unlockMethod = .password("password123")

        let task = Task {
            await subject.perform(.listenForNFC)
        }

        waitFor(!coordinator.events.isEmpty)
        task.cancel()

        XCTAssertTrue(nfcReaderService.didStartReading)
        XCTAssertEqual(subject.state.verificationCode, "NFC_TAG_VALUE")
        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
        XCTAssertEqual(authRepository.unlockVaultPassword, "password123")

        subject = nil
        XCTAssertTrue(nfcReaderService.didStopReading)
    }

    /// `perform(_:)` with `.listenForNFC` logs an error and shows an alert if listening for NFC tags fails.
    func test_perform_listenForNFC_error() async {
        nfcReaderService.resultSubject.send(completion: .failure(BitwardenTestError.example))

        await subject.perform(.listenForNFC)

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertEqual(coordinator.alertShown, [.networkResponseError(BitwardenTestError.example)])
    }

    /// `perform(_:)` with `.receivedDuoToken` handles an error correctly.
    func test_perform_receivedDuoToken_failure() async {
        subject.state.authMethod = .duo
        subject.state.verificationCode = ""
        authService.loginWithTwoFactorCodeResult = .failure(BitwardenTestError.example)

        await subject.perform(.receivedDuoToken("DuoToken"))

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.invalidVerificationCode
        ))
    }

    /// `perform(_:)` with `.receivedDuoToken` handles a two-factor error correctly.
    func test_perform_receivedDuoToken_noUnlockMethod() async {
        subject.state.authMethod = .duo
        subject.state.verificationCode = ""
        subject.state.unlockMethod = nil
        let expectedAccount = Account.fixtureAccountLogin()
        authService.loginWithTwoFactorCodeResult = .success(expectedAccount)

        await subject.perform(.receivedDuoToken("DuoToken"))

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(
            coordinator.routes,
            [
                .vaultUnlock(
                    expectedAccount,
                    animated: false,
                    attemptAutomaticBiometricUnlock: true,
                    didSwitchAccountAutomatically: false
                ),
                .dismiss,
            ]
        )
    }

    /// `perform(_:)` with `.receivedDuoToken` logs in and unlocks the vault successfully when using
    /// a duo.
    func test_perform_receivedDuoToken_success() async {
        subject.state.authMethod = .duo
        subject.state.verificationCode = ""
        subject.state.unlockMethod = .password("duo token")
        authService.loginWithTwoFactorCodeResult = .success(.fixtureAccountLogin())

        await subject.perform(.receivedDuoToken("DuoToken"))

        XCTAssertEqual(subject.state.verificationCode, "DuoToken")
        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
        XCTAssertEqual(authRepository.unlockVaultPassword, "duo token")
    }

    /// `perform(_:)` with `.resendEmailTapped` handles errors correctly.
    func test_perform_resendEmailTapped_error() async {
        subject.state.authMethod = .email
        authService.resendVerificationCodeEmailResult = .failure(BitwardenTestError.example)

        await subject.perform(.resendEmailTapped)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown.last, LoadingOverlayState(title: Localizations.submitting))
        XCTAssertEqual(
            coordinator.alertShown.last,
            .defaultAlert(title: Localizations.anErrorHasOccurred,
                          message: Localizations.verificationEmailNotSent)
        )
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.resendEmailTapped` does nothing when not required.
    func test_perform_resendEmailTapped_notRequired() async {
        subject.state.authMethod = .duo

        await subject.perform(.resendEmailTapped)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertNil(coordinator.loadingOverlaysShown.last)
        XCTAssertNil(subject.state.toast?.text, Localizations.verificationEmailSent)
    }

    /// `perform(_:)` with `.resendEmailTapped` sends the email and displays the toast.
    func test_perform_resendEmailTapped_success() async {
        subject.state.authMethod = .email

        await subject.perform(.resendEmailTapped)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown.last, LoadingOverlayState(title: Localizations.submitting))
        XCTAssertEqual(subject.state.toast?.text, Localizations.verificationEmailSent)
    }

    /// `perform(_:)` with `.tryAgainTapped` starts reading NFC tags.
    func test_perform_tryAgainTapped() async {
        subject.state.authMethod = .yubiKey

        await subject.perform(.tryAgainTapped)

        XCTAssertTrue(nfcReaderService.didStartReading)
    }

    /// `receive(_:)` with `.authMethodSelected` updates the value in the state.
    func test_receive_authMethodSelected() {
        subject.receive(.authMethodSelected(.authenticatorApp))
        XCTAssertEqual(subject.state.authMethod, .authenticatorApp)
    }

    /// `receive(_:)` `.authMethodSelected` with `.email` sends a code to the user's email.
    func test_receive_authMethodSelected_email() {
        authService.resendVerificationCodeEmailResult = .success(())
        subject.state.authMethod = .webAuthn
        subject.receive(.authMethodSelected(.email))
        waitFor(authService.sentVerificationEmail)
        XCTAssertEqual(subject.state.authMethod, .email)
    }

    /// `receive(_:)` with `.authMethodSelected` opens the url for the recover code.
    func test_receive_authMethodSelected_recoveryCode() {
        subject.state.authMethod = .email
        subject.receive(.authMethodSelected(.recoveryCode))
        XCTAssertEqual(subject.state.authMethod, .email)
        XCTAssertEqual(subject.state.url, URL(string: "\(environmentService.recoveryCodeURL)"))
    }

    /// `receive(_:)` with `.clearURL` clears the URL in the state.
    func test_receive_clearURL() {
        subject.state.url = .example
        subject.receive(.clearURL)
        XCTAssertNil(subject.state.url)
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.rememberMeToggleChanged` updates the value in the state.
    func test_receive_rememberMeToggleChanged() {
        subject.receive(.rememberMeToggleChanged(true))
        XCTAssertTrue(subject.state.isRememberMeOn)
        subject.receive(.rememberMeToggleChanged(false))
        XCTAssertFalse(subject.state.isRememberMeOn)
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    func test_receive_toastShown() {
        let toast = Toast(text: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// `receive(_:)` with `.verificationCodeChanged` updates the value in the state and enables the button if
    /// applicable.
    func test_receive_verificationCodeChanged() {
        subject.receive(.verificationCodeChanged("123"))
        XCTAssertEqual(subject.state.verificationCode, "123")
        XCTAssertFalse(subject.state.continueEnabled)

        subject.receive(.verificationCodeChanged("123456"))
        XCTAssertEqual(subject.state.verificationCode, "123456")
        XCTAssertTrue(subject.state.continueEnabled)
    }
}
