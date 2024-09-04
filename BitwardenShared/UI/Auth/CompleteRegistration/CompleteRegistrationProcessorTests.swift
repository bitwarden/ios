import AuthenticationServices
import Networking
import XCTest

@testable import BitwardenShared

// MARK: - CompleteRegistrationProcessorTests

// swiftlint:disable:next type_body_length
class CompleteRegistrationProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var authService: MockAuthService!
    var client: MockHTTPClient!
    var clientAuth: MockClientAuth!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var subject: CompleteRegistrationProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        authRepository = MockAuthRepository()
        authService = MockAuthService()
        client = MockHTTPClient()
        clientAuth = MockClientAuth()
        configService = MockConfigService()
        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        subject = CompleteRegistrationProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                authService: authService,
                clientService: MockClientService(auth: clientAuth),
                configService: configService,
                environmentService: environmentService,
                errorReporter: errorReporter,
                httpClient: client
            ),
            state: CompleteRegistrationState(
                emailVerificationToken: "emailVerificationToken",
                userEmail: "example@email.com"
            )
        )
    }

    override func tearDown() {
        super.tearDown()
        authRepository = nil
        authService = nil
        clientAuth = nil
        client = nil
        coordinator = nil
        configService = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(.appeared)` with EU region in state.
    @MainActor
    func test_perform_appeared_setRegion_europe() async {
        subject.state.region = .europe
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .europe)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentUrlsData, .defaultEU)
    }

    /// `perform(.appeared)` with nil region in state.
    @MainActor
    func test_perform_appeared_setRegion_return() async {
        subject.state.region = nil
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, nil)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentUrlsData, nil)
    }

    /// `perform(.appeared)` verify user email show toast on success.
    @MainActor
    func test_perform_appeared_verifyuseremail_success() async {
        client.results = [.httpSuccess(testData: .emptyResponse)]
        subject.state.fromEmail = true
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.toast?.text, Localizations.emailVerified)
    }

    /// `perform(.appeared)` verify user email show no toast.
    @MainActor
    func test_perform_appeared_verifyuseremail_notFromEmail() async {
        subject.state.fromEmail = false
        await subject.perform(.appeared)
        XCTAssertNil(subject.state.toast)
    }

    /// `perform(.appeared)` verify user email hide loading.
    @MainActor
    func test_perform_appeared_verifyuseremail_hideloading() async {
        coordinator.isLoadingOverlayShowing = true
        subject.state.fromEmail = false
        await subject.perform(.appeared)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertNotNil(coordinator.loadingOverlaysShown)
    }

    /// `perform(.appeared)` verify user email with token expired error shows expired link screen.
    @MainActor
    func test_perform_appeared_verifyuseremail_tokenexpired() async {
        client.results = [
            .httpFailure(
                statusCode: 400,
                headers: [:],
                data: APITestData.verifyEmailTokenExpiredLink.data
            ),
        ]
        subject.state.fromEmail = true
        await subject.perform(.appeared)
        XCTAssertEqual(coordinator.routes.last, .expiredLink)
    }

    /// `perform(.appeared)` verify user email presents an alert when there is no internet connection.
    /// When the user taps `Try again`, the verify user email request is made again.
    @MainActor
    func test_perform_appeared_verifyuseremail_error() async throws {
        subject.state = .fixture()
        subject.state.fromEmail = true

        let urlError = URLError(.notConnectedToInternet) as Error
        client.results = [.httpFailure(urlError), .httpSuccess(testData: .emptyResponse)]

        await subject.perform(.appeared)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, Alert.networkResponseError(urlError) {
            await self.subject.perform(.appeared)
        })

        try await alert.tapAction(title: Localizations.tryAgain)

        XCTAssertEqual(subject.state.toast?.text, Localizations.emailVerified)
        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].url, URL(
            string: "https://example.com/identity/accounts/register/verification-email-clicked"
        ))
        XCTAssertEqual(client.requests[1].url, URL(
            string: "https://example.com/identity/accounts/register/verification-email-clicked"
        ))

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(
            coordinator.loadingOverlaysShown,
            [
                LoadingOverlayState(title: Localizations.verifying),
                LoadingOverlayState(title: Localizations.verifying),
            ]
        )
    }

    /// `perform(.appeared)` with feature flag for .nativeCreateAccountFlow set to true
    @MainActor
    func test_perform_appeared_loadFeatureFlag_true() async {
        configService.featureFlagsBool[.nativeCreateAccountFlow] = true
        subject.state.nativeCreateAccountFeatureFlag = false

        await subject.perform(.appeared)
        XCTAssertTrue(subject.state.nativeCreateAccountFeatureFlag)
    }

    /// `perform(.appeared)` with feature flag for .nativeCreateAccountFlow set to false
    @MainActor
    func test_perform_appeared_loadsFeatureFlag_false() async {
        configService.featureFlagsBool[.nativeCreateAccountFlow] = false
        subject.state.nativeCreateAccountFeatureFlag = true

        await subject.perform(.appeared)
        XCTAssertFalse(subject.state.nativeCreateAccountFeatureFlag)
    }

    /// `perform(.appeared)` with feature flag defaulting to false
    @MainActor
    func test_perform_appeared_loadsFeatureFlag_nil() async {
        configService.featureFlagsBool[.nativeCreateAccountFlow] = nil
        subject.state.nativeCreateAccountFeatureFlag = true

        await subject.perform(.appeared)
        XCTAssertFalse(subject.state.nativeCreateAccountFeatureFlag)
    }

    /// `perform(_:)` with `.completeRegistration` will still make the `CompleteRegistrationRequest` when the HIBP
    /// network request fails.
    @MainActor
    func test_perform_checkPasswordAndCompleteRegistration_failure() async throws {
        authService.loginWithMasterPasswordResult = .success(())
        subject.state = .fixture(isCheckDataBreachesToggleOn: true)

        client.results = [
            .httpFailure(URLError(.timedOut) as Error),
            .httpSuccess(testData: .createAccountRequest),
        ]

        await subject.perform(.completeRegistration)

        XCTAssertEqual(authService.loginWithMasterPasswordPassword, "password1234")
        XCTAssertNil(authService.loginWithMasterPasswordCaptchaToken)
        XCTAssertEqual(authService.loginWithMasterPasswordUsername, "email@example.com")

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://api.pwnedpasswords.com/range/e6b6a"))
        XCTAssertEqual(client.requests[1].url, URL(string: "https://example.com/identity/accounts/register/finish"))

        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(
            coordinator.loadingOverlaysShown,
            [
                LoadingOverlayState(title: Localizations.creatingAccount),
                LoadingOverlayState(title: Localizations.creatingAccount),
            ]
        )
    }

    /// `perform(_:)` with `.completeRegistration` presents an alert when the password
    /// is weak and exposed. This also tests that the correct alert is presented.
    /// Additionally, this tests that tapping Yes on the alert creates the account.
    @MainActor
    func test_perform_checkPasswordAndCompleteRegistration_exposedWeak_yesTapped() async throws {
        subject.state = .fixture(isCheckDataBreachesToggleOn: true, passwordStrengthScore: 1)

        client.results = [.httpSuccess(testData: .hibpLeakedPasswords), .httpSuccess(testData: .createAccountRequest)]

        await subject.perform(.completeRegistration)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://api.pwnedpasswords.com/range/e6b6a"))
        XCTAssertEqual(client.requests[1].url, URL(string: "https://example.com/identity/accounts/register/finish"))
        XCTAssertEqual(coordinator.alertShown.last, Alert(
            title: Localizations.weakAndExposedMasterPassword,
            message: Localizations.weakPasswordIdentifiedAndFoundInADataBreachAlertDescription,
            alertActions: [
                AlertAction(title: Localizations.no, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in },
            ]
        ))

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(
            coordinator.loadingOverlaysShown,
            [
                LoadingOverlayState(title: Localizations.creatingAccount),
                LoadingOverlayState(title: Localizations.creatingAccount),
            ]
        )
    }

    /// `perform(_:)` with `.completeRegistration` presents an alert when the password
    /// is strong and exposed. This also tests that the correct alert is presented.
    /// Additionally, this tests that tapping Yes on the alert creates the account.
    @MainActor
    func test_perform_checkPasswordAndCompleteRegistration_exposedStrong_yesTapped() async throws {
        subject.state = .fixture(isCheckDataBreachesToggleOn: true, passwordStrengthScore: 3)

        client.results = [.httpSuccess(testData: .hibpLeakedPasswords), .httpSuccess(testData: .createAccountRequest)]

        await subject.perform(.completeRegistration)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://api.pwnedpasswords.com/range/e6b6a"))
        XCTAssertEqual(client.requests[1].url, URL(string: "https://example.com/identity/accounts/register/finish"))
        XCTAssertEqual(coordinator.alertShown.last, Alert(
            title: Localizations.exposedMasterPassword,
            message: Localizations.passwordFoundInADataBreachAlertDescription,
            alertActions: [
                AlertAction(title: Localizations.no, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in },
            ]
        ))

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(
            coordinator.loadingOverlaysShown,
            [
                LoadingOverlayState(title: Localizations.creatingAccount),
                LoadingOverlayState(title: Localizations.creatingAccount),
            ]
        )
    }

    /// `perform(_:)` with `.completeRegistration` presents an alert when the password
    /// is weak and unchecked against breaches. This also tests that the correct alert is presented.
    /// Additionally, this tests that tapping Yes on the alert creates the account.
    @MainActor
    func test_perform_checkPasswordAndCompleteRegistration_uncheckedWeak_yesTapped() async throws {
        subject.state = .fixture(
            isCheckDataBreachesToggleOn: false,
            passwordText: "unexposed123",
            passwordStrengthScore: 2,
            retypePasswordText: "unexposed123"
        )

        client.results = [.httpSuccess(testData: .createAccountRequest)]

        await subject.perform(.completeRegistration)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/identity/accounts/register/finish"))
        XCTAssertEqual(coordinator.alertShown.last, Alert(
            title: Localizations.weakMasterPassword,
            message: Localizations.weakPasswordIdentifiedUseAStrongPasswordToProtectYourAccount,
            alertActions: [
                AlertAction(title: Localizations.no, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in },
            ]
        ))

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
    }

    /// `perform(_:)` with `.completeRegistration` presents an alert when the password
    /// is weak and unexposed. This also tests that the correct alert is presented.
    /// Additionally, this tests that tapping Yes on the alert creates the account.
    @MainActor
    func test_perform_checkPasswordAndCompleteRegistration_unexposedWeak_yesTapped() async throws {
        subject.state = .fixture(
            isCheckDataBreachesToggleOn: true,
            passwordText: "unexposed123",
            passwordStrengthScore: 2,
            retypePasswordText: "unexposed123"
        )

        client.results = [.httpSuccess(testData: .hibpLeakedPasswords), .httpSuccess(testData: .createAccountRequest)]

        await subject.perform(.completeRegistration)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://api.pwnedpasswords.com/range/6bf92"))
        XCTAssertEqual(client.requests[1].url, URL(string: "https://example.com/identity/accounts/register/finish"))
        XCTAssertEqual(coordinator.alertShown.last, Alert(
            title: Localizations.weakMasterPassword,
            message: Localizations.weakPasswordIdentifiedUseAStrongPasswordToProtectYourAccount,
            alertActions: [
                AlertAction(title: Localizations.no, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in },
            ]
        ))

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(
            coordinator.loadingOverlaysShown,
            [
                LoadingOverlayState(title: Localizations.creatingAccount),
                LoadingOverlayState(title: Localizations.creatingAccount),
            ]
        )
    }

    /// `perform(_:)` with `.completeRegistration` presents an alert when the email has already been taken.
    @MainActor
    func test_perform_completeRegistration_accountAlreadyExists() async {
        subject.state = .fixture()

        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.createAccountAccountAlreadyExists.data
        )

        guard let errorResponse = try? ErrorResponseModel(response: response) else { return }

        client.result = .httpFailure(
            ServerError.error(errorResponse: errorResponse)
        )

        await subject.perform(.completeRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(
            coordinator.alertShown.last,
            .defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: "Email 'j@a.com' is already taken."
            )
        )

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
    }

    /// `perform(_:)` with `.completeRegistration` presents an alert when the password field is empty.
    @MainActor
    func test_perform_completeRegistration_emptyPassword() async {
        subject.state = .fixture(passwordText: "", retypePasswordText: "")

        client.result = .httpSuccess(testData: .createAccountRequest)

        await subject.perform(.completeRegistration)

        XCTAssertEqual(client.requests.count, 0)
        XCTAssertEqual(coordinator.alertShown.last, .validationFieldRequired(fieldName: "Master password"))
        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
    }

    /// `perform(_:)` with `.completeRegistration` presents an alert when the password hint is too long.
    @MainActor
    func test_perform_completeRegistration_hintTooLong() async {
        subject.state = .fixture(passwordHintText: """
        ajajajajajajajajajajajajajajajajajajajajajajajajajajajajajajajajajajaj
        ajajajajajajajajajajajajajajajajajajajajajajajajajajajajajsjajajajajaj
        """)

        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.createAccountHintTooLong.data
        )

        guard let errorResponse = try? ErrorResponseModel(response: response) else { return }

        client.result = .httpFailure(
            ServerError.error(errorResponse: errorResponse)
        )

        await subject.perform(.completeRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(
            coordinator.alertShown.last,
            .defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: "The field MasterPasswordHint must be a string with a maximum length of 50."
            )
        )

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
    }

    /// `perform(_:)` with `.completeRegistration` presents an alert when the email is in an invalid format.
    @MainActor
    func test_perform_completeRegistration_invalidEmailFormat() async {
        subject.state = .fixture(userEmail: "∫@ø.com")

        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.createAccountInvalidEmailFormat.data
        )

        guard let errorResponse = try? ErrorResponseModel(response: response) else { return }

        client.result = .httpFailure(
            ServerError.error(errorResponse: errorResponse)
        )

        await subject.perform(.completeRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(
            coordinator.alertShown.last,
            .defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: "The Email field is not a supported e-mail address format."
            )
        )

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
    }

    /// `perform(_:)` with `.completeRegistration` presents an alert when there is no internet connection.
    /// When the user taps `Try again`, the create account request is made again.
    @MainActor
    func test_perform_completeRegistration_noInternetConnection() async throws {
        authService.loginWithMasterPasswordResult = .success(())
        subject.state = .fixture()

        let urlError = URLError(.notConnectedToInternet) as Error
        client.results = [.httpFailure(urlError), .httpSuccess(testData: .createAccountRequest)]

        await subject.perform(.completeRegistration)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, Alert.networkResponseError(urlError) {
            await self.subject.perform(.completeRegistration)
        })

        try await alert.tapAction(title: Localizations.tryAgain)

        XCTAssertEqual(authService.loginWithMasterPasswordPassword, "password1234")
        XCTAssertNil(authService.loginWithMasterPasswordCaptchaToken)
        XCTAssertEqual(authService.loginWithMasterPasswordUsername, "email@example.com")

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/identity/accounts/register/finish"))
        XCTAssertEqual(client.requests[1].url, URL(string: "https://example.com/identity/accounts/register/finish"))

        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(
            coordinator.loadingOverlaysShown,
            [
                LoadingOverlayState(title: Localizations.creatingAccount),
                LoadingOverlayState(title: Localizations.creatingAccount),
            ]
        )
    }

    /// `perform(_:)` with `.completeRegistration` presents an alert when password confirmation is incorrect.
    @MainActor
    func test_perform_completeRegistration_passwordsDontMatch() async {
        subject.state = .fixture(passwordText: "123456789012", retypePasswordText: "123456789000")

        client.result = .httpSuccess(testData: .createAccountRequest)

        await subject.perform(.completeRegistration)

        XCTAssertEqual(client.requests.count, 0)
        XCTAssertEqual(coordinator.alertShown.last, .passwordsDontMatch)
        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
    }

    /// `perform(_:)` with `.completeRegistration` presents an alert when the password isn't long enough.
    @MainActor
    func test_perform_completeRegistration_passwordsTooShort() async {
        subject.state = .fixture(passwordText: "123", retypePasswordText: "123")

        client.result = .httpSuccess(testData: .createAccountRequest)

        await subject.perform(.completeRegistration)

        XCTAssertEqual(client.requests.count, 0)
        XCTAssertEqual(coordinator.alertShown.last, .passwordIsTooShort)
        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
    }

    /// `perform(_:)` with `.completeRegistration` presents an alert when the request times out.
    /// When the user taps `Try again`, the create account request is made again.
    @MainActor
    func test_perform_completeRegistration_timeout() async throws {
        authService.loginWithMasterPasswordResult = .success(())
        subject.state = .fixture()

        let urlError = URLError(.timedOut) as Error
        client.results = [.httpFailure(urlError), .httpSuccess(testData: .createAccountRequest)]

        await subject.perform(.completeRegistration)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.message, urlError.localizedDescription)

        try await alert.tapAction(title: Localizations.tryAgain)

        XCTAssertEqual(authService.loginWithMasterPasswordPassword, "password1234")
        XCTAssertNil(authService.loginWithMasterPasswordCaptchaToken)
        XCTAssertEqual(authService.loginWithMasterPasswordUsername, "email@example.com")

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/identity/accounts/register/finish"))
        XCTAssertEqual(client.requests[1].url, URL(string: "https://example.com/identity/accounts/register/finish"))

        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(
            coordinator.loadingOverlaysShown,
            [
                LoadingOverlayState(title: Localizations.creatingAccount),
                LoadingOverlayState(title: Localizations.creatingAccount),
            ]
        )
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismissPresented)
    }

    /// `receive(_:)` with `.learnMoreTapped` launches the master password guidance view.
    @MainActor
    func test_receive_learnMoreTapped() {
        subject.receive(.learnMoreTapped)
        XCTAssertEqual(coordinator.routes.last, .masterPasswordGuidance)
    }

    /// `receive(_:)` with `.passwordHintTextChanged(_:)` updates the state to reflect the change.
    @MainActor
    func test_receive_passwordHintTextChanged() {
        subject.state.passwordHintText = ""
        XCTAssertTrue(subject.state.passwordHintText.isEmpty)

        subject.receive(.passwordHintTextChanged("updated hint"))
        XCTAssertTrue(subject.state.passwordHintText == "updated hint")
    }

    /// `receive(_:)` with `.passwordTextChanged(_:)` updates the state to reflect the change.
    @MainActor
    func test_receive_passwordTextChanged() {
        subject.state.passwordText = ""
        XCTAssertTrue(subject.state.passwordText.isEmpty)

        subject.receive(.passwordTextChanged("updated password"))
        XCTAssertTrue(subject.state.passwordText == "updated password")
    }

    /// `receive(_:)` with `.passwordTextChanged(_:)` updates the password strength score based on
    /// the entered password.
    @MainActor
    func test_receive_passwordTextChanged_updatesPasswordStrength() {
        subject.state.userEmail = "user@bitwarden.com"
        subject.receive(.passwordTextChanged(""))
        XCTAssertNil(subject.state.passwordStrengthScore)
        XCTAssertNil(authRepository.passwordStrengthPassword)

        authRepository.passwordStrengthResult = 0
        subject.receive(.passwordTextChanged("T"))
        waitFor(subject.state.passwordStrengthScore == 0)
        XCTAssertEqual(subject.state.passwordStrengthScore, 0)
        XCTAssertEqual(authRepository.passwordStrengthEmail, "user@bitwarden.com")
        XCTAssertEqual(authRepository.passwordStrengthPassword, "T")

        authRepository.passwordStrengthResult = 4
        subject.receive(.passwordTextChanged("TestPassword1234567890!@#"))
        waitFor(subject.state.passwordStrengthScore == 4)
        XCTAssertEqual(subject.state.passwordStrengthScore, 4)
        XCTAssertEqual(authRepository.passwordStrengthEmail, "user@bitwarden.com")
        XCTAssertEqual(authRepository.passwordStrengthPassword, "TestPassword1234567890!@#")
    }

    /// `receive(_:)` with `.retypePasswordTextChanged(_:)` updates the state to reflect the change.
    @MainActor
    func test_receive_retypePasswordTextChanged() {
        subject.state.retypePasswordText = ""
        XCTAssertTrue(subject.state.retypePasswordText.isEmpty)

        subject.receive(.retypePasswordTextChanged("updated re-type"))
        XCTAssertTrue(subject.state.retypePasswordText == "updated re-type")
    }

    /// `receive(_:)` with `.toggleCheckDataBreaches(_:)` updates the state to reflect the change.
    @MainActor
    func test_receive_toggleCheckDataBreaches() {
        subject.receive(.toggleCheckDataBreaches(false))
        XCTAssertFalse(subject.state.isCheckDataBreachesToggleOn)

        subject.receive(.toggleCheckDataBreaches(true))
        XCTAssertTrue(subject.state.isCheckDataBreachesToggleOn)

        subject.receive(.toggleCheckDataBreaches(true))
        XCTAssertTrue(subject.state.isCheckDataBreachesToggleOn)
    }

    /// `receive(_:)` with `.togglePasswordVisibility(_:)` updates the state to reflect the change.
    @MainActor
    func test_receive_togglePasswordVisibility() {
        subject.state.arePasswordsVisible = false

        subject.receive(.togglePasswordVisibility(true))
        XCTAssertTrue(subject.state.arePasswordsVisible)

        subject.receive(.togglePasswordVisibility(true))
        XCTAssertTrue(subject.state.arePasswordsVisible)

        subject.receive(.togglePasswordVisibility(false))
        XCTAssertFalse(subject.state.arePasswordsVisible)
    }

    /// `receive(_:)` with `.showToast` show toast.
    @MainActor
    func test_receive_showToast() {
        subject.receive(.toastShown(Toast(text: "example")))
        XCTAssertEqual(subject.state.toast?.text, "example")
    }
    // swiftlint:disable:next file_length
}
