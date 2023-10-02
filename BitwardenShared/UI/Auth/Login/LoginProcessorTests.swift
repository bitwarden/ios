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
    }

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
    }

    func test_perform_loginWithMasterPasswordPressed_preLoginError() async {
        client.results = [
            .httpFailure(BitwardenTestError.example),
        ]
        subject.state.username = "email@example.com"
        subject.state.masterPassword = "Password1234!"
        await subject.perform(.loginWithMasterPasswordPressed)

        XCTAssertEqual(client.requests.count, 1)
        // TODO: BIT-709 Add an assertion for the error alert.
    }

    func test_perform_loginWithMasterPasswordPressed_identityTokenError() async {
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpFailure(BitwardenTestError.example),
        ]
        subject.state.username = "email@example.com"
        subject.state.masterPassword = "Password1234!"
        await subject.perform(.loginWithMasterPasswordPressed)

        XCTAssertEqual(client.requests.count, 2)
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
