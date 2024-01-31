import XCTest

@testable import BitwardenShared

class LoginWithDeviceProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var authService: MockAuthService!
    var coordinator: MockCoordinator<AuthRoute>!
    var errorReporter: MockErrorReporter!
    var subject: LoginWithDeviceProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        authService = MockAuthService()
        coordinator = MockCoordinator<AuthRoute>()
        errorReporter = MockErrorReporter()

        subject = LoginWithDeviceProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                authService: authService,
                errorReporter: errorReporter
            ),
            state: LoginWithDeviceState()
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
        authService.initiateLoginWithDeviceResult = .success(("fingerprint", "id"))
        authService.checkPendingLoginRequestResult = .success(approvedLoginRequest)
        authService.loginWithDeviceResult = .success(("PRIVATE_KEY", "KEY"))
        subject.state.email = "user@bitwarden.com"

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(!coordinator.routes.isEmpty)
        task.cancel()

        XCTAssertEqual(authService.checkPendingLoginRequestId, "id")

        XCTAssertEqual(authService.loginWithDeviceEmail, "user@bitwarden.com")
        XCTAssertEqual(authService.loginWithDeviceRequest, approvedLoginRequest)

        XCTAssertEqual(authRepository.unlockVaultFromLoginWithDeviceKey, "KEY")
        XCTAssertEqual(authRepository.unlockVaultFromLoginWithDevicePrivateKey, "PRIVATE_KEY")
        XCTAssertEqual(authRepository.unlockVaultFromLoginWithDeviceMasterPasswordHash, "reallyLongMasterPasswordHash")

        XCTAssertEqual(coordinator.routes, [.dismiss, .complete])
    }

    /// `captchaErrored(error:)` records an error.
    func test_captchaErrored() {
        subject.captchaErrored(error: BitwardenTestError.example)

        waitFor(!coordinator.alertShown.isEmpty)
        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(BitwardenTestError.example))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.appeared` sets the fingerprint phrase in the state.
    func test_perform_appeared() async {
        authService.initiateLoginWithDeviceResult = .success(("fingerprint", "id"))
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
        authService.initiateLoginWithDeviceResult = .success(("fingerprint2", "id"))

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.fingerprintPhrase, "fingerprint2")
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }
}
