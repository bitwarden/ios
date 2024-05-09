import AuthenticationServices
import XCTest

@testable import BitwardenShared

class LoginWithDeviceProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var authService: MockAuthService!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var subject: LoginWithDeviceProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        authService = MockAuthService()
        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        errorReporter = MockErrorReporter()

        subject = LoginWithDeviceProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                authService: authService,
                errorReporter: errorReporter
            ),
            state: LoginWithDeviceState(requestType: AuthRequestType.authenticateAndUnlock)
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        authService = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `attemptLogin()` kicks off the login flow, starts a timer to check for responses and
    /// completes login for an approved response.
    func test_attemptLogin() {
        let approvedLoginRequest = LoginRequest.fixture(requestApproved: true, responseDate: .now)
        authService.initiateLoginWithDeviceResult = .success((.fixture(fingerprint: "fingerprint"), "id"))
        authService.checkPendingLoginRequestResult = .success(approvedLoginRequest)
        authService.loginWithDeviceResult = .success(("PRIVATE_KEY", "KEY"))
        subject.state.email = "user@bitwarden.com"

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(!coordinator.events.isEmpty)
        task.cancel()

        XCTAssertEqual(authService.checkPendingLoginRequestId, "id")

        XCTAssertEqual(authService.loginWithDeviceEmail, "user@bitwarden.com")
        XCTAssertEqual(authService.loginWithDeviceRequest, approvedLoginRequest)

        XCTAssertEqual(authRepository.unlockVaultFromLoginWithDeviceKey, "KEY")
        XCTAssertEqual(authRepository.unlockVaultFromLoginWithDevicePrivateKey, "PRIVATE_KEY")
        XCTAssertEqual(authRepository.unlockVaultFromLoginWithDeviceMasterPasswordHash, "reallyLongMasterPasswordHash")

        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
    }

    /// `textBasedOnRequestType(adminApproval:)` labels should changed based on request type
    func test_textBasedOnRequestType_adminApproval() {
        subject.state.requestType = AuthRequestType.adminApproval

        XCTAssertFalse(subject.state.isResendNotificationVisible)
        XCTAssertEqual(subject.state.explanationText, Localizations.yourRequestHasBeenSentToYourAdmin)
        XCTAssertEqual(subject.state.navBarText, Localizations.logInInitiated)
        XCTAssertEqual(subject.state.titleText, Localizations.adminApprovalRequested)
    }

    /// `textBasedOnRequestType(authenticateAndUnlock:)` labels should changed based on request type
    func test_textBasedOnRequestType_authenticateAndUnlock() {
        subject.state.requestType = AuthRequestType.authenticateAndUnlock

        XCTAssertTrue(subject.state.isResendNotificationVisible)
        XCTAssertEqual(
            subject.state.explanationText,
            Localizations.aNotificationHasBeenSentToYourDevice +
                .newLine +
                Localizations.pleaseMakeSureYourVaultIsUnlockedAndTheFingerprintPhraseMatchesOnTheOtherDevice
        )
        XCTAssertEqual(subject.state.navBarText, Localizations.logInWithDevice)
        XCTAssertEqual(subject.state.titleText, Localizations.logInInitiated)
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

    /// `checkForResponse()`stops the request timer if the request has been denied.
    func test_checkForResponse_denied() throws {
        let deniedLoginRequest = LoginRequest.fixture(requestApproved: false, responseDate: .now)
        authService.checkPendingLoginRequestResult = .success(deniedLoginRequest)

        let task = Task {
            await self.subject.perform(.appeared)
        }
        waitFor(subject.checkTimer?.isValid == false)
        task.cancel()

        try XCTAssertFalse(XCTUnwrap(subject.checkTimer).isValid)
        XCTAssertTrue(coordinator.alertShown.isEmpty)
        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `checkForResponse()` stops the request timer if the request returns an error. Once the error
    /// alert has been dismissed, requests resume again.
    func test_checkForResponse_error() throws {
        authService.checkPendingLoginRequestResult = .failure(BitwardenTestError.example)

        let task = Task {
            await self.subject.perform(.appeared)
        }
        waitFor(!coordinator.alertShown.isEmpty)
        task.cancel()

        XCTAssertEqual(coordinator.alertShown, [.networkResponseError(BitwardenTestError.example)])

        authService.checkPendingLoginRequestResult = .success(.fixture(requestApproved: true))
        coordinator.alertOnDismissed?()
        waitFor(!coordinator.events.isEmpty)

        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
    }

    /// `checkForResponse()` stops the request timer if the request has expired.
    func test_checkForResponse_expired() throws {
        authService.checkPendingLoginRequestResult = .failure(CheckLoginRequestError.expired)

        let task = Task {
            await self.subject.perform(.appeared)
        }
        waitFor(subject.checkTimer?.isValid == false)
        task.cancel()

        try XCTAssertFalse(XCTUnwrap(subject.checkTimer).isValid)
        XCTAssertTrue(coordinator.alertShown.isEmpty)
        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `checkForResponse()` navigates the user to the two factor flow if it's required to complete login.
    func test_checkForResponse_twoFactorRequired() {
        let approvedLoginRequest = LoginRequest.fixture(requestApproved: true, responseDate: .now)
        authService.initiateLoginWithDeviceResult = .success((.fixture(fingerprint: "fingerprint"), "id"))
        authService.checkPendingLoginRequestResult = .success(approvedLoginRequest)
        authService.loginWithDeviceResult = .failure(
            IdentityTokenRequestError.twoFactorRequired(AuthMethodsData(), nil, nil)
        )

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(!coordinator.routes.isEmpty)
        task.cancel()

        XCTAssertEqual(
            coordinator.routes.last,
            .twoFactor(
                "",
                .loginWithDevice(
                    key: "reallyLongKey",
                    masterPasswordHash: "reallyLongMasterPasswordHash",
                    privateKey: "PRIVATE_KEY"
                ),
                AuthMethodsData(),
                nil
            )
        )
    }

    /// `perform(_:)` with `.appeared` sets the fingerprint phrase in the state.
    func test_perform_appeared() async {
        authService.initiateLoginWithDeviceResult = .success((.fixture(fingerprint: "fingerprint"), "id"))
        subject.state.email = "user@bitwarden.com"

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.fingerprintPhrase, "fingerprint")
        XCTAssertEqual(subject.state.requestId, "id")
        XCTAssertEqual(authService.initiateLoginWithDeviceEmail, "user@bitwarden.com")
    }

    /// `perform(_:)` with `.appeared` handles any errors.
    func test_perform_appeared_error() async {
        authService.initiateLoginWithDeviceResult = .failure(BitwardenTestError.example)

        await subject.perform(.appeared)

        XCTAssertEqual(coordinator.alertShown.last, Alert.defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.resendNotification` updates the fingerprint phrase in the state.
    func test_perform_resendNotification() async {
        authService.initiateLoginWithDeviceResult = .success((.fixture(fingerprint: "fingerprint2"), "id"))

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.fingerprintPhrase, "fingerprint2")
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }
}
