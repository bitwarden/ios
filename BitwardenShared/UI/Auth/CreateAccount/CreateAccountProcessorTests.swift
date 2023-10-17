import XCTest

@testable import BitwardenShared

// MARK: - CreateAccountProcessorTests

class CreateAccountProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var captchaService: MockCaptchaService!
    var client: MockHTTPClient!
    var clientAuth: MockClientAuth!
    var coordinator: MockCoordinator<AuthRoute>!
    var subject: CreateAccountProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        captchaService = MockCaptchaService()
        client = MockHTTPClient()
        clientAuth = MockClientAuth()
        coordinator = MockCoordinator<AuthRoute>()
        subject = CreateAccountProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                captchaService: captchaService,
                clientAuth: clientAuth,
                httpClient: client
            ),
            state: CreateAccountState()
        )
    }

    override func tearDown() {
        super.tearDown()
        captchaService = nil
        clientAuth = nil
        client = nil
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `captchaCompleted()` makes the create account request again, this time with a captcha token.
    /// Also tests that the user is then navigated to the login screen.
    func test_captchaCompleted() throws {
        clientAuth.hashPasswordResult = .success("hashed password")
        client.result = .httpSuccess(testData: .createAccountRequest)

        subject.state.emailText = "example@email.com"
        subject.state.passwordText = "password1234"
        subject.state.isTermsAndPrivacyToggleOn = true
        subject.captchaCompleted(token: "token")

        let createAccountRequest = CreateAccountRequestModel(
            captchaResponse: "token",
            email: "example@email.com",
            kdfConfig: KdfConfig(),
            key: "encryptedUserKey",
            keys: KeysRequestModel(
                publicKey: "public",
                encryptedPrivateKey: "private"
            ),
            masterPasswordHash: "hashed password",
            masterPasswordHint: ""
        )

        waitFor(!coordinator.routes.isEmpty)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].body, try createAccountRequest.encode())
        XCTAssertEqual(clientAuth.hashPasswordPassword, "password1234")
        XCTAssertEqual(clientAuth.hashPasswordKdfParams, .pbkdf2(iterations: 600_000))
        XCTAssertEqual(
            coordinator.routes.last,
            .login(
                username: "example@email.com",
                region: LoginState().region,
                isLoginWithDeviceVisible: LoginState().isLoginWithDeviceVisible
            )
        )
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `perform(_:)` with `.createAccount` presents an alert when the user has
    /// entered a password that has been found in a data breach. After tapping `Yes` to create
    /// an account anyways, the `CreateAccountRequest` is made.
    func test_perform_checkForBreachesAndCreateAccount_yesTapped() async throws {
        let password = "12345abcde"
        subject.state.emailText = "example@email.com"
        subject.state.passwordText = password
        subject.state.retypePasswordText = password
        subject.state.isCheckDataBreachesToggleOn = true
        subject.state.isTermsAndPrivacyToggleOn = true

        client.results = [.httpSuccess(testData: .hibpLeakedPasswords), .httpSuccess(testData: .createAccountRequest)]
        await subject.perform(.createAccount)

        guard case let .alert(alert) = coordinator.routes.last else {
            return XCTFail("Expected an `.alert` route, but found \(String(describing: coordinator.routes.last))")
        }
        await alert.alertActions[1].handler?(alert.alertActions[1])

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://api.pwnedpasswords.com/range/dec7d"))
        XCTAssertEqual(client.requests[1].url, URL(string: "https://example.com/identity/accounts/register"))
    }

    /// `perform(_:)` with `.createAccount` presents an alert when the user has
    /// entered a password that has been found in a data breach.
    func test_perfrom_checkForBreachesAndCreateAccount() async {
        let password = "12345abcde"
        subject.state.passwordText = password
        subject.state.retypePasswordText = password
        subject.state.isCheckDataBreachesToggleOn = true

        client.result = .httpSuccess(testData: .hibpLeakedPasswords)
        await subject.perform(.createAccount)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://api.pwnedpasswords.com/range/dec7d"))
        XCTAssertEqual(coordinator.routes.last, .alert(Alert(
            title: Localizations.weakAndExposedMasterPassword,
            message: Localizations.weakPasswordIdentifiedAndFoundInADataBreachAlertDescription,
            alertActions: [
                AlertAction(title: Localizations.no, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in },
            ]
        )))
    }

    /// `perform(_:)` with `.createAccount` and a captcha error occurs navigates to the `.captcha` route.
    func test_createAccount_captchaError() async {
        client.result = .httpFailure(CreateAccountRequestError.captchaRequired(hCaptchaSiteCode: "token"))

        captchaService.generateCaptchaUrlValue = .example
        subject.state.emailText = "email@example.com"
        subject.state.passwordText = "password1234"
        subject.state.retypePasswordText = "password1234"
        subject.state.isTermsAndPrivacyToggleOn = true
        await subject.perform(.createAccount)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(captchaService.callbackUrlSchemeGets, 1)
        XCTAssertEqual(captchaService.generateCaptchaSiteKey, "token")
        XCTAssertEqual(coordinator.routes.last, .captcha(url: .example, callbackUrlScheme: "callback"))
    }

    /// `perform(_:)` with `.createAccount` and an invalid email navigates to an invalid email alert.
    func test_perform_createAccount_withInvalidEmail() async {
        client.result = .httpSuccess(testData: .createAccountSuccess)
        subject.state.isCheckDataBreachesToggleOn = true
        subject.state.isTermsAndPrivacyToggleOn = true
        subject.state.emailText = ""

        await subject.perform(.createAccount)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(coordinator.routes.last, .alert(.invalidEmail))
    }

    /// `perform(_:)` with `.createAccount` and a valid email creates the user's account.
    func test_perform_createAccount_withValidEmail() async {
        client.result = .httpSuccess(testData: .createAccountSuccess)
        subject.state.isCheckDataBreachesToggleOn = true
        subject.state.isTermsAndPrivacyToggleOn = true
        subject.state.emailText = "email@example.com"

        await subject.perform(.createAccount)

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests.first?.body, nil)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://api.pwnedpasswords.com/range/da39a"))
        XCTAssertEqual(client.requests[1].url, URL(string: "https://example.com/identity/accounts/register"))
    }

    /// `perform(_:)` with `.createAccount` and a valid email surrounded by whitespace trims the whitespace and
    /// creates the user's account
    func test_perform_createAccount_withValidEmailAndSpace() async {
        client.result = .httpSuccess(testData: .createAccountSuccess)
        subject.state.isCheckDataBreachesToggleOn = true
        subject.state.isTermsAndPrivacyToggleOn = true
        subject.state.emailText = " email@example.com "

        await subject.perform(.createAccount)

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests.first?.body, nil)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://api.pwnedpasswords.com/range/da39a"))
        XCTAssertEqual(client.requests[1].url, URL(string: "https://example.com/identity/accounts/register"))
    }

    /// `perform(_:)` with `.createAccount` and a valid email with uppercase characters converts the email to lowercase
    /// and creates the user's account.
    func test_perform_createAccount_withValidEmailUppercased() async {
        client.result = .httpSuccess(testData: .createAccountSuccess)
        subject.state.isCheckDataBreachesToggleOn = true
        subject.state.isTermsAndPrivacyToggleOn = true
        subject.state.emailText = "EMAIL@EXAMPLE.COM"

        await subject.perform(.createAccount)

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests.first?.body, nil)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://api.pwnedpasswords.com/range/da39a"))
        XCTAssertEqual(client.requests[1].url, URL(string: "https://example.com/identity/accounts/register"))
    }

    /// `perform(_:)` with `.createAccount` creates the user's account.
    func test_perform_createAccount_withTermsAndServicesToggle_false() async {
        client.result = .httpSuccess(testData: .createAccountSuccess)
        subject.state.isCheckDataBreachesToggleOn = true
        subject.state.isTermsAndPrivacyToggleOn = false
        subject.state.emailText = "email@example.com"

        await subject.perform(.createAccount)

        XCTAssertEqual(client.requests.count, 1)
        // TODO: BIT-681 Add an assertion here for an error alert.
    }

    /// `receive(_:)` with `.emailTextChanged(_:)` updates the state to reflect the change.
    func test_receive_emailTextChanged() {
        subject.state.emailText = ""
        XCTAssertTrue(subject.state.emailText.isEmpty)

        subject.receive(.emailTextChanged("updated email"))
        XCTAssertTrue(subject.state.emailText == "updated email")
    }

    /// `receive(_:)` with `.passwordHintTextChanged(_:)` updates the state to reflect the change.
    func test_receive_passwordHintTextChanged() {
        subject.state.passwordHintText = ""
        XCTAssertTrue(subject.state.passwordHintText.isEmpty)

        subject.receive(.passwordHintTextChanged("updated hint"))
        XCTAssertTrue(subject.state.passwordHintText == "updated hint")
    }

    /// `receive(_:)` with `.passwordTextChanged(_:)` updates the state to reflect the change.
    func test_receive_passwordTextChanged() {
        subject.state.passwordText = ""
        XCTAssertTrue(subject.state.passwordText.isEmpty)

        subject.receive(.passwordTextChanged("updated password"))
        XCTAssertTrue(subject.state.passwordText == "updated password")
    }

    /// `receive(_:)` with `.passwordTextChanged(_:)` updates the password strength score based on
    /// the entered password.
    func test_receive_passwordTextChanged_updatesPasswordStrength() {
        subject.receive(.passwordTextChanged(""))
        XCTAssertNil(subject.state.passwordStrengthScore)

        subject.receive(.passwordTextChanged("T"))
        XCTAssertEqual(subject.state.passwordStrengthScore, 0)

        subject.receive(.passwordTextChanged("Test"))
        XCTAssertEqual(subject.state.passwordStrengthScore, 1)

        subject.receive(.passwordTextChanged("TestPass"))
        XCTAssertEqual(subject.state.passwordStrengthScore, 2)

        subject.receive(.passwordTextChanged("TestPasswo"))
        XCTAssertEqual(subject.state.passwordStrengthScore, 3)

        subject.receive(.passwordTextChanged("TestPassword123"))
        XCTAssertEqual(subject.state.passwordStrengthScore, 4)

        subject.receive(.passwordTextChanged("TestPassword1234567890!@#"))
        XCTAssertEqual(subject.state.passwordStrengthScore, 4)
    }

    /// `receive(_:)` with `.retypePasswordTextChanged(_:)` updates the state to reflect the change.
    func test_receive_retypePasswordTextChanged() {
        subject.state.retypePasswordText = ""
        XCTAssertTrue(subject.state.retypePasswordText.isEmpty)

        subject.receive(.retypePasswordTextChanged("updated re-type"))
        XCTAssertTrue(subject.state.retypePasswordText == "updated re-type")
    }

    /// `receive(_:)` with `.toggleCheckDataBreaches(_:)` updates the state to reflect the change.
    func test_receive_toggleCheckDataBreaches() {
        subject.receive(.toggleCheckDataBreaches(false))
        XCTAssertFalse(subject.state.isCheckDataBreachesToggleOn)

        subject.receive(.toggleCheckDataBreaches(true))
        XCTAssertTrue(subject.state.isCheckDataBreachesToggleOn)

        subject.receive(.toggleCheckDataBreaches(true))
        XCTAssertTrue(subject.state.isCheckDataBreachesToggleOn)
    }

    /// `receive(_:)` with `.togglePasswordVisibility(_:)` updates the state to reflect the change.
    func test_receive_togglePasswordVisibility() {
        subject.state.arePasswordsVisible = false

        subject.receive(.togglePasswordVisibility(true))
        XCTAssertTrue(subject.state.arePasswordsVisible)

        subject.receive(.togglePasswordVisibility(true))
        XCTAssertTrue(subject.state.arePasswordsVisible)

        subject.receive(.togglePasswordVisibility(false))
        XCTAssertFalse(subject.state.arePasswordsVisible)
    }

    /// `receive(_:)` with `.toggleTermsAndPrivacy(_:)` updates the state to reflect the change.
    func test_receive_toggleTermsAndPrivacy() {
        subject.receive(.toggleTermsAndPrivacy(false))
        XCTAssertFalse(subject.state.isTermsAndPrivacyToggleOn)

        subject.receive(.toggleTermsAndPrivacy(true))
        XCTAssertTrue(subject.state.isTermsAndPrivacyToggleOn)

        subject.receive(.toggleTermsAndPrivacy(true))
        XCTAssertTrue(subject.state.isTermsAndPrivacyToggleOn)
    }
}
