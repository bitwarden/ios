import AuthenticationServices
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import Networking
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - CompleteRegistrationProcessorTests

// swiftlint:disable:next type_body_length
class CompleteRegistrationProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var authService: MockAuthService!
    var client: MockHTTPClient!
    var authClient: MockAuthClient!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var subject: CompleteRegistrationProcessor!
    var stateService: MockStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        authRepository = MockAuthRepository()
        authService = MockAuthService()
        client = MockHTTPClient()
        authClient = MockAuthClient()
        configService = MockConfigService()
        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        subject = CompleteRegistrationProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                authService: authService,
                clientService: MockClientService(auth: authClient),
                configService: configService,
                environmentService: environmentService,
                errorReporter: errorReporter,
                httpClient: client,
                stateService: stateService
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
        authClient = nil
        client = nil
        coordinator = nil
        configService = nil
        errorReporter = nil
        subject = nil
        stateService = nil
    }

    // MARK: Tests

    /// `perform(.appeared)` with EU region in state.
    @MainActor
    func test_perform_appeared_setRegion_europe() async {
        let email = "email@example.com"
        subject.state.userEmail = email
        subject.state.fromEmail = true
        await stateService.setAccountCreationEnvironmentURLs(urls: .defaultEU, email: email)
        await subject.perform(.appeared)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentURLsData, .defaultEU)
    }

    /// `perform(.appeared)` fromEmail false  returns.
    @MainActor
    func test_perform_appeared_setRegion_notFromEmail_returns() async throws {
        let email = "email@example.com"
        subject.state.userEmail = email
        subject.state.fromEmail = false
        await stateService.setAccountCreationEnvironmentURLs(urls: .defaultEU, email: email)
        await subject.perform(.appeared)
        XCTAssertNil(coordinator.alertShown.last)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentURLsData, nil)
    }

    /// `perform(.appeared)` fromEmail true and no saved region for given email shows alert.
    @MainActor
    func test_perform_appeared_setRegion_noRegion_alert() async throws {
        let email = "email@example.com"
        subject.state.userEmail = email
        subject.state.fromEmail = true
        await stateService.setAccountCreationEnvironmentURLs(urls: .defaultEU, email: "another_email@example.com")
        await subject.perform(.appeared)
        XCTAssertEqual(
            coordinator.alertShown[0],
            .defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.theRegionForTheGivenEmailCouldNotBeLoaded
            )
        )
        XCTAssertEqual(environmentService.setPreAuthEnvironmentURLsData, nil)
    }

    /// `perform(.appeared)` verify user email show toast on success.
    @MainActor
    func test_perform_appeared_verifyuseremail_success() async {
        client.results = [.httpSuccess(testData: .emptyResponse)]
        subject.state.fromEmail = true
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.emailVerified))
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

        let urlError = URLError(.notConnectedToInternet)
        client.results = [.httpFailure(urlError), .httpSuccess(testData: .emptyResponse)]

        await subject.perform(.appeared)

        let alertWithRetry = try XCTUnwrap(coordinator.errorAlertsWithRetryShown.last)
        XCTAssertEqual(alertWithRetry.error as? URLError, urlError)

        await alertWithRetry.retry()

        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.emailVerified))
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

    /// `perform(_:)` with `.completeRegistration` will still make the `CompleteRegistrationRequest` when the HIBP
    /// network request fails.
    @MainActor
    func test_perform_checkPasswordAndCompleteRegistration_failure() async throws {
        authService.loginWithMasterPasswordResult = .success(())
        subject.state = .fixture(isCheckDataBreachesToggleOn: true)

        client.results = [
            .httpFailure(URLError(.timedOut) as Error),
            .httpSuccess(testData: .registerFinishRequest),
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

        client.results = [.httpSuccess(testData: .hibpLeakedPasswords), .httpSuccess(testData: .registerFinishRequest)]

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

        client.results = [.httpSuccess(testData: .hibpLeakedPasswords), .httpSuccess(testData: .registerFinishRequest)]

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

        client.results = [.httpSuccess(testData: .registerFinishRequest)]

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

        client.results = [.httpSuccess(testData: .hibpLeakedPasswords), .httpSuccess(testData: .registerFinishRequest)]

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
            body: APITestData.registerFinishAccountAlreadyExists.data
        )

        guard let errorResponse = try? ErrorResponseModel(response: response) else { return }
        let error = ServerError.error(errorResponse: errorResponse)
        client.result = .httpFailure(error)

        await subject.perform(.completeRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(coordinator.errorAlertsWithRetryShown.last?.error as? ServerError, error)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
    }

    /// `perform(_:)` with `.completeRegistration` presents an alert when the password field is empty.
    @MainActor
    func test_perform_completeRegistration_emptyPassword() async {
        subject.state = .fixture(passwordText: "", retypePasswordText: "")

        client.result = .httpSuccess(testData: .registerFinishRequest)

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
            body: APITestData.registerFinishHintTooLong.data
        )

        guard let errorResponse = try? ErrorResponseModel(response: response) else { return }
        let error = ServerError.error(errorResponse: errorResponse)
        client.result = .httpFailure(error)

        await subject.perform(.completeRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(coordinator.errorAlertsWithRetryShown.last?.error as? ServerError, error)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
    }

    /// `perform(_:)` with `.completeRegistration` presents an alert when the email is in an invalid format.
    @MainActor
    func test_perform_completeRegistration_invalidEmailFormat() async {
        subject.state = .fixture(userEmail: "∫@ø.com")

        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.registerFinishInvalidEmailFormat.data
        )

        guard let errorResponse = try? ErrorResponseModel(response: response) else { return }
        let error = ServerError.error(errorResponse: errorResponse)
        client.result = .httpFailure(error)

        await subject.perform(.completeRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(coordinator.errorAlertsWithRetryShown.last?.error as? ServerError, error)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
    }

    /// `perform(_:)` with `.completeRegistration` navigates to login if the create account request
    /// succeeds, but login fails.
    @MainActor
    func test_perform_completeRegistration_loginError() async throws {
        authService.loginWithMasterPasswordResult = .failure(BitwardenTestError.example)
        client.result = .httpSuccess(testData: .registerFinishRequest)
        subject.state = .fixture()

        await subject.perform(.completeRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/identity/accounts/register/finish"))

        XCTAssertTrue(coordinator.alertShown.isEmpty)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(
            coordinator.loadingOverlaysShown,
            [
                LoadingOverlayState(title: Localizations.creatingAccount),
            ]
        )
        XCTAssertEqual(coordinator.routes.count, 1)
        guard case let .dismissWithAction(dismissAction) = coordinator.routes.first else {
            return XCTFail("Unable to find dismiss action.")
        }
        dismissAction?.action()
        XCTAssertEqual(coordinator.routes.count, 2)
        XCTAssertEqual(coordinator.routes[1], .login(username: "email@example.com", isNewAccount: true))
        XCTAssertEqual(coordinator.toastsShown, [Toast(title: Localizations.accountSuccessfullyCreated)])
    }

    /// `perform(_:)` with `.completeRegistration` navigates to login if the create account and
    /// login requests succeed, but vault unlocking fails.
    @MainActor
    func test_perform_completeRegistration_unlockError() async throws {
        authRepository.unlockWithPasswordResult = .failure(BitwardenTestError.example)
        client.result = .httpSuccess(testData: .registerFinishRequest)
        subject.state = .fixture()

        await subject.perform(.completeRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/identity/accounts/register/finish"))

        XCTAssertTrue(coordinator.alertShown.isEmpty)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(
            coordinator.loadingOverlaysShown,
            [
                LoadingOverlayState(title: Localizations.creatingAccount),
            ]
        )
        XCTAssertEqual(coordinator.routes.count, 1)
        guard case let .dismissWithAction(dismissAction) = coordinator.routes.first else {
            return XCTFail("Unable to find dismiss action.")
        }
        dismissAction?.action()
        XCTAssertEqual(coordinator.routes.count, 2)
        XCTAssertEqual(coordinator.routes[1], .login(username: "email@example.com", isNewAccount: true))
        XCTAssertEqual(coordinator.toastsShown, [Toast(title: Localizations.accountSuccessfullyCreated)])
    }

    /// `perform(_:)` with `.completeRegistration` presents an alert when there is no internet connection.
    /// When the user taps `Try again`, the create account request is made again.
    @MainActor
    func test_perform_completeRegistration_noInternetConnection() async throws {
        authService.loginWithMasterPasswordResult = .success(())
        subject.state = .fixture()

        let urlError = URLError(.notConnectedToInternet)
        client.results = [.httpFailure(urlError), .httpSuccess(testData: .registerFinishRequest)]

        await subject.perform(.completeRegistration)

        let alertWithRetry = try XCTUnwrap(coordinator.errorAlertsWithRetryShown.last)
        XCTAssertEqual(alertWithRetry.error as? URLError, urlError)

        await alertWithRetry.retry()

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

        client.result = .httpSuccess(testData: .registerFinishRequest)

        await subject.perform(.completeRegistration)

        XCTAssertEqual(client.requests.count, 0)
        XCTAssertEqual(coordinator.alertShown.last, .passwordsDontMatch)
        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
    }

    /// `perform(_:)` with `.completeRegistration` presents an alert when the password isn't long enough.
    @MainActor
    func test_perform_completeRegistration_passwordsTooShort() async {
        subject.state = .fixture(passwordText: "123", retypePasswordText: "123")

        client.result = .httpSuccess(testData: .registerFinishRequest)

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

        let urlError = URLError(.timedOut)
        client.results = [.httpFailure(urlError), .httpSuccess(testData: .registerFinishRequest)]

        await subject.perform(.completeRegistration)

        let alertWithRetry = try XCTUnwrap(coordinator.errorAlertsWithRetryShown.last)
        XCTAssertEqual(alertWithRetry.error as? URLError, urlError)

        await alertWithRetry.retry()

        XCTAssertEqual(authService.loginWithMasterPasswordPassword, "password1234")
        XCTAssertNil(authService.loginWithMasterPasswordCaptchaToken)
        XCTAssertEqual(authService.loginWithMasterPasswordUsername, "email@example.com")
        XCTAssertTrue(authService.loginWithMasterPasswordIsNewAccount)

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
        XCTAssertNotNil(coordinator.contexts.last as? CompleteRegistrationProcessor)
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

        authRepository.passwordStrengthResult = .success(0)
        subject.receive(.passwordTextChanged("T"))
        waitFor(subject.state.passwordStrengthScore == 0)
        XCTAssertEqual(authRepository.passwordStrengthEmail, "user@bitwarden.com")
        XCTAssertTrue(authRepository.passwordStrengthIsPreAuth)
        XCTAssertEqual(authRepository.passwordStrengthPassword, "T")

        authRepository.passwordStrengthResult = .success(4)
        subject.receive(.passwordTextChanged("TestPassword1234567890!@#"))
        waitFor(subject.state.passwordStrengthScore == 4)
        XCTAssertEqual(authRepository.passwordStrengthEmail, "user@bitwarden.com")
        XCTAssertTrue(authRepository.passwordStrengthIsPreAuth)
        XCTAssertEqual(authRepository.passwordStrengthPassword, "TestPassword1234567890!@#")
    }

    /// `receive(_:)` with `.passwordTextChanged(_:)` records an error if the `.passwordStrength()` throws.
    @MainActor
    func test_receive_passwordTextChanged_updatePasswordStrength_fails() {
        authRepository.passwordStrengthResult = .failure(BitwardenTestError.example)
        subject.receive(.passwordTextChanged("T"))
        waitFor(!errorReporter.errors.isEmpty)
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, BitwardenTestError.example)
    }

    /// `receive(_:)` with `.preventAccountLockTapped` navigates to the right route.
    @MainActor
    func test_receive_preventAccountLock() {
        subject.receive(.preventAccountLockTapped)
        XCTAssertEqual(coordinator.routes.last, .preventAccountLock)
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
        let toast = Toast(title: "example")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)
    }

    /// Tests `didUpdateMasterPassword` correctly updates the state and navigates correctly.
    @MainActor
    func test_didUpdateMasterPassword() {
        let expectedPassword = "215-Go-Birds-🦅"
        subject.didUpdateMasterPassword(password: expectedPassword)
        XCTAssertEqual(subject.state.passwordText, expectedPassword)
        XCTAssertEqual(subject.state.retypePasswordText, expectedPassword)
    }
    // swiftlint:disable:next file_length
}
