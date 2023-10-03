import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - LoginProcessorTests

class LoginProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var captchaService: MockCaptchaService!
    var client: MockHTTPClient!
    var clientAuth: MockClientAuth!
    var coordinator: MockCoordinator<AuthRoute>!
    var subject: LoginProcessor!
    var systemDevice: MockSystemDevice!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        appSettingsStore = MockAppSettingsStore()
        captchaService = MockCaptchaService()
        client = MockHTTPClient()
        clientAuth = MockClientAuth()
        coordinator = MockCoordinator()
        systemDevice = MockSystemDevice()
        subject = LoginProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                appSettingsStore: appSettingsStore,
                captchaService: captchaService,
                clientAuth: clientAuth,
                systemDevice: systemDevice,
                httpClient: client
            ),
            state: LoginState()
        )
    }

    override func tearDown() {
        super.tearDown()
        appSettingsStore = nil
        captchaService = nil
        client = nil
        clientAuth = nil
        coordinator = nil
        subject = nil
        systemDevice = nil
    }

    // MARK: Tests

    /// `captchaCompleted()` makes the login requests again, this time with a captcha token.
    func test_captchaCompleted() {
        appSettingsStore.appId = "App id"
        systemDevice.modelIdentifier = "Model id"
        clientAuth.hashPasswordValue = "hashed password"
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpSuccess(testData: .identityTokenSuccess),
        ]
        subject.state.username = "email@example.com"
        subject.state.masterPassword = "Password1234!"

        subject.captchaCompleted(token: "token")

        let preLoginRequest = PreLoginRequestModel(
            email: "email@example.com"
        )
        let tokenRequest = IdentityTokenRequestModel(
            authenticationMethod: .password(
                username: "email@example.com",
                password: "hashed password"
            ),
            captchaToken: "token",
            deviceInfo: DeviceInfo(
                identifier: "App id",
                name: "Model id"
            )
        )

        waitFor(!coordinator.routes.isEmpty)

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].body, try preLoginRequest.encode())
        XCTAssertEqual(client.requests[1].body, try tokenRequest.encode())

        XCTAssertEqual(clientAuth.hashPasswordEmail, "email@example.com")
        XCTAssertEqual(clientAuth.hashPasswordPassword, "Password1234!")
        XCTAssertEqual(clientAuth.hashPasswordKdfParams, .pbkdf2(iterations: 600_000))

        XCTAssertEqual(coordinator.routes.last, .complete)
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
        appSettingsStore.appId = "App id"
        systemDevice.modelIdentifier = "Model id"
        clientAuth.hashPasswordValue = "hashed password"
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpSuccess(testData: .identityTokenSuccess),
        ]
        subject.state.username = "email@example.com"
        subject.state.masterPassword = "Password1234!"

        await subject.perform(.loginWithMasterPasswordPressed)

        let preLoginRequest = PreLoginRequestModel(
            email: "email@example.com"
        )
        let tokenRequest = IdentityTokenRequestModel(
            authenticationMethod: .password(
                username: "email@example.com",
                password: "hashed password"
            ),
            captchaToken: nil,
            deviceInfo: DeviceInfo(
                identifier: "App id",
                name: "Model id"
            )
        )

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].body, try preLoginRequest.encode())
        XCTAssertEqual(client.requests[1].body, try tokenRequest.encode())

        XCTAssertEqual(clientAuth.hashPasswordEmail, "email@example.com")
        XCTAssertEqual(clientAuth.hashPasswordPassword, "Password1234!")
        XCTAssertEqual(clientAuth.hashPasswordKdfParams, .pbkdf2(iterations: 600_000))

        XCTAssertEqual(coordinator.routes.last, .complete)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [.init(title: Localizations.loggingIn)])
    }

    /// `perform(_:)` with `.loginWithMasterPasswordPressed` and a captcha error occurs navigates to the `.captcha`
    /// route.
    func test_perform_loginWithMasterPasswordPressed_captchaError() async {
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpFailure(IdentityTokenRequestError.captchaRequired(hCaptchaSiteCode: "token")),
        ]
        captchaService.generateCaptchaUrlValue = .example
        subject.state.username = "email@example.com"
        subject.state.masterPassword = "Password1234!"
        await subject.perform(.loginWithMasterPasswordPressed)

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(captchaService.callbackUrlSchemeGets, 1)
        XCTAssertEqual(captchaService.generateCaptchaSiteKey, "token")
        XCTAssertEqual(coordinator.routes.last, .captcha(url: .example, callbackUrlScheme: "callback"))
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [.init(title: Localizations.loggingIn)])
    }

    /// `perform(_:)` with `.loginWithMasterPasswordPressed` and an error with the pre-login request displays an error
    /// alert.
    func test_perform_loginWithMasterPasswordPressed_preLoginError() async {
        client.results = [
            .httpFailure(BitwardenTestError.example),
        ]
        subject.state.username = "email@example.com"
        subject.state.masterPassword = "Password1234!"
        await subject.perform(.loginWithMasterPasswordPressed)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [.init(title: Localizations.loggingIn)])
        // TODO: BIT-709 Add an assertion for the error alert.
    }

    /// `perform(_:)` with `.loginWithMasterPasswordPressed` and an error with the identity token request displays an
    /// error alert.
    func test_perform_loginWithMasterPasswordPressed_identityTokenError() async {
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpFailure(BitwardenTestError.example),
        ]
        subject.state.username = "email@example.com"
        subject.state.masterPassword = "Password1234!"
        await subject.perform(.loginWithMasterPasswordPressed)

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [.init(title: Localizations.loggingIn)])
        // TODO: BIT-709 Add an assertion for the error alert.
    }

    /// `receive(_:)` with `.enterpriseSingleSignOnPressed` navigates to the enterprise single sign-on screen.
    func test_receive_enterpriseSingleSignOnPressed() {
        subject.receive(.enterpriseSingleSignOnPressed)
        XCTAssertEqual(coordinator.routes.last, .enterpriseSingleSignOn)
    }

    /// `receive(_:)` with `.getMasterPasswordHintPressed` navigates to the master password hint screen.
    func test_receive_getMasterPasswordHintPressed() {
        subject.receive(.getMasterPasswordHintPressed)
        XCTAssertEqual(coordinator.routes.last, .masterPasswordHint)
    }

    /// `receive(_:)` with `.loginWithDevicePressed` navigates to the login with device screen.
    func test_receive_loginWithDevicePressed() {
        subject.receive(.loginWithDevicePressed)
        XCTAssertEqual(coordinator.routes.last, .loginWithDevice)
    }

    /// `receive(_:)` with `.masterPasswordChanged` updates the state to reflect the changes.
    func test_receive_masterPasswordChanged() {
        subject.state.masterPassword = ""

        subject.receive(.masterPasswordChanged("password"))
        XCTAssertEqual(subject.state.masterPassword, "password")
    }

    /// `receive(_:)` with `.morePressed` navigates to the login options screen.
    func test_receive_morePressed() {
        subject.receive(.morePressed)
        XCTAssertEqual(coordinator.routes.last, .loginOptions)
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
