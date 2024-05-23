import AuthenticationServices
import Networking
import XCTest

@testable import BitwardenShared

// MARK: - StartRegistrationProcessorTests

class StartRegistrationProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var captchaService: MockCaptchaService!
    var client: MockHTTPClient!
    var clientAuth: MockClientAuth!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var subject: StartRegistrationProcessor!
    var delegate: MockStartRegistrationDelegate!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        authRepository = MockAuthRepository()
        captchaService = MockCaptchaService()
        client = MockHTTPClient()
        clientAuth = MockClientAuth()
        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        errorReporter = MockErrorReporter()
        subject = StartRegistrationProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                captchaService: captchaService,
                clientService: MockClientService(auth: clientAuth),
                errorReporter: errorReporter,
                httpClient: client
            ),
            state: StartRegistrationState()
        )
    }

    override func tearDown() {
        super.tearDown()
        authRepository = nil
        captchaService = nil
        clientAuth = nil
        client = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `captchaCompleted()` makes the create account request again, this time with a captcha token.
    /// Also tests that the user is then navigated to the login screen.
    func test_captchaCompleted() throws {
        StartRegistrationRequestModel.encoder.outputFormatting = .sortedKeys
        subject.state = .fixture()
        client.result = .httpSuccess(testData: .startRegistrationSuccess)
        subject.captchaCompleted(token: "token")

        let startRegistrationRequest = StartRegistrationRequestModel(
            captchaResponse: "token",
            email: "example@email.com",
            name: "name"
        )

        waitFor(!coordinator.routes.isEmpty)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].body, try startRegistrationRequest.encode())
        XCTAssertEqual(coordinator.routes.last, .completeRegistration(
            emailVerificationToken: "emailVerificationToken",
            userEmail: "example@email.com"
        ))
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

    /// `perform(_:)` with `.startRegistration` presents an alert when the email has already been taken.
    func test_perform_startRegistration_emailExists() async {
        subject.state = .fixture()

        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.startRegistrationEmailAlreadyExists.data
        )

        guard let errorResponse = try? ErrorResponseModel(response: response) else { return }

        client.result = .httpFailure(
            ServerError.error(errorResponse: errorResponse)
        )

        await subject.perform(.startRegistration)

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

    /// `perform(_:)` with `.startRegistration` presents an alert when the email exceeds the maximum length.
    func test_perform_startRegistration_emailExceedsMaxLength() async {
        subject.state = .fixture(emailText: """
        eyrztwlvxqdksnmcbjgahfpouyqiwubfdzoxhjsrlnvgeatkcpimy\
        fqaxhztsowbmdkjlrpnuqvycigfexrvlosqtpnheujawzsdmkbfoy\
        cxqpwkzthbnmudxlysgarcejfqvopzrkihwdelbuxyfqnjsgptamcozrvihsl\
        nbujrtdosmvhxwyfapzcklqoxbgdvtfieqyuhwajnrpslmcskgzofdqehxcbv\
        omjltzafwudqypnisgrkeohycbvxjflaumtwzrdqnpsoiezgyhqbmxdlvnzwa\
        htjoekrcispgvyfbuqklszepjwdrantihxfcoygmuslqbajzdfgrkmwbpnouq\
        tlsvixechyfjslrdvngiwzqpcotxubamhyekufjrzdwmxihqkfonslbcjgtpu\
        voyaezrctudwlskjpvmfqhnxbriyg@example.com
        """)

        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.startRegistrationEmailExceedsMaxLength.data
        )

        guard let errorResponse = try? ErrorResponseModel(response: response) else { return }

        client.result = .httpFailure(
            ServerError.error(errorResponse: errorResponse)
        )

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(
            coordinator.alertShown.last,
            .defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: "The field Email must be a string with a maximum length of 256."
            )
        )

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
    }

    /// `perform(_:)` with `.startRegistration` presents an alert when the email field is empty.
    func test_perform_startRegistration_emptyEmail() async {
        subject.state = .fixture(emailText: "")

        client.result = .httpSuccess(testData: .startRegistrationSuccess)

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 0)
        XCTAssertEqual(coordinator.alertShown.last, .validationFieldRequired(fieldName: "Email"))
        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
    }

    /// `perform(_:)` with `.startRegistration` and a captcha required error occurs navigates to the `.captcha` route.
    func test_perform_startRegistration_captchaError() async {
        subject.state = .fixture()

        client.result = .httpFailure(StartRegistrationRequestError.captchaRequired(hCaptchaSiteCode: "token"))

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(captchaService.callbackUrlSchemeGets, 1)
        XCTAssertEqual(captchaService.generateCaptchaSiteKey, "token")
        XCTAssertEqual(coordinator.routes.last, .captcha(url: .example, callbackUrlScheme: "callback"))

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
    }

    /// `perform(_:)` with `.startRegistration` and a captcha flow error records the error.
    func test_perform_startRegistration_captchaFlowError() async {
        captchaService.generateCaptchaUrlResult = .failure(BitwardenTestError.example)
        client.result = .httpFailure(StartRegistrationRequestError.captchaRequired(hCaptchaSiteCode: "token"))

        subject.state = .fixture()

        await subject.perform(.startRegistration)

        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(BitwardenTestError.example))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
    }

    /// `perform(_:)` with `.startRegistration` presents an alert when the email is in an invalid format.
    func test_perform_startRegistration_invalidEmailFormat() async {
        subject.state = .fixture(emailText: "∫@ø.com")

        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.startRegistrationInvalidEmailFormat.data
        )

        guard let errorResponse = try? ErrorResponseModel(response: response) else { return }

        client.result = .httpFailure(
            ServerError.error(errorResponse: errorResponse)
        )

        await subject.perform(.startRegistration)

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

    /// `perform(_:)` with `.startRegistration` presents an alert when there is no internet connection.
    /// When the user taps `Try again`, the create account request is made again.
    func test_perform_startRegistration_noInternetConnection() async throws {
        subject.state = .fixture()

        let urlError = URLError(.notConnectedToInternet) as Error
        client.results = [.httpFailure(urlError), .httpSuccess(testData: .startRegistrationSuccess)]

        await subject.perform(.startRegistration)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, Alert.networkResponseError(urlError) {
            await self.subject.perform(.startRegistration)
        })

        try await alert.tapAction(title: Localizations.tryAgain)

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/api/accounts/send-verification-email"))
        XCTAssertEqual(client.requests[1].url, URL(string: "https://example.com/api/accounts/send-verification-email"))
        XCTAssertEqual(coordinator.routes.last, .completeRegistration(
            emailVerificationToken: "emailVerificationToken",
            userEmail: "example@email.com"
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

    /// `perform(_:)` with `.startRegistration` presents an alert when the request times out.
    /// When the user taps `Try again`, the create account request is made again.
    func test_perform_startRegistration_timeout() async throws {
        subject.state = .fixture()

        let urlError = URLError(.timedOut) as Error
        client.results = [.httpFailure(urlError), .httpSuccess(testData: .startRegistrationSuccess)]

        await subject.perform(.startRegistration)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.message, urlError.localizedDescription)

        try await alert.tapAction(title: Localizations.tryAgain)

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/api/accounts/send-verification-email"))
        XCTAssertEqual(client.requests[1].url, URL(string: "https://example.com/api/accounts/send-verification-email"))
        XCTAssertEqual(coordinator.routes.last, .completeRegistration(
            emailVerificationToken: "emailVerificationToken",
            userEmail: "example@email.com"
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

    /// `perform(_:)` with `.startRegistration` and an invalid email navigates to an invalid email alert.
    func test_perform_startRegistration_withInvalidEmail() async {
        subject.state = .fixture(emailText: "exampleemail.com")

        client.result = .httpFailure(StartRegistrationError.invalidEmail)

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 0)
        XCTAssertEqual(coordinator.alertShown.last, .invalidEmail)
        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
    }

    /// `perform(_:)` with `.startRegistration` and a valid email creates the user's account.
    func test_perform_startRegistration_withValidEmail() async {
        subject.state = .fixture()

        client.result = .httpSuccess(testData: .startRegistrationSuccess)

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/api/accounts/send-verification-email"))

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
    }

    /// `perform(_:)` with `.startRegistration` and a valid email surrounded by whitespace trims the whitespace and
    /// creates the user's account
    func test_perform_startRegistration_withValidEmailAndSpace() async {
        subject.state = .fixture(emailText: " email@example.com ")

        client.result = .httpSuccess(testData: .startRegistrationSuccess)

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/api/accounts/send-verification-email"))

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
    }

    /// `perform(_:)` with `.startRegistration` and a valid email with uppercase characters
    /// converts the email to lowercase
    /// and creates the user's account.
    func test_perform_startRegistration_withValidEmailUppercased() async {
        subject.state = .fixture(emailText: "EMAIL@EXAMPLE.COM")

        client.result = .httpSuccess(testData: .startRegistrationSuccess)

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/api/accounts/send-verification-email"))

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
    }

    /// `perform(_:)` with `.startRegistration` navigates to an error alert when the terms of service
    /// and privacy policy toggle is off.
    func test_perform_startRegistration_withTermsAndServicesToggle_false() async {
        subject.state = .fixture(isTermsAndPrivacyToggleOn: false)

        client.result = .httpSuccess(testData: .startRegistrationSuccess)

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 0)
        XCTAssertEqual(coordinator.alertShown.last, .acceptPoliciesAlert())
        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.emailTextChanged(_:)` updates the state to reflect the change.
    func test_receive_emailTextChanged() {
        subject.state.emailText = ""
        XCTAssertTrue(subject.state.emailText.isEmpty)

        subject.receive(.emailTextChanged("updated email"))
        XCTAssertTrue(subject.state.emailText == "updated email")
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

class MockStartRegistrationDelegate: StartRegistrationDelegate {
    var didChangeRegionCalled: Bool = false

    func didChangeRegion() async {
        didChangeRegionCalled = true
    }
} // swiftlint:disable:this file_length
