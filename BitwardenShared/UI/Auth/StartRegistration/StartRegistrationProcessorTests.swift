import AuthenticationServices
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import Networking
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - StartRegistrationProcessorTests

class StartRegistrationProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var captchaService: MockCaptchaService!
    var client: MockHTTPClient!
    var authClient: MockAuthClient!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var delegate: MockStartRegistrationDelegate!
    var errorReporter: MockErrorReporter!
    var subject: StartRegistrationProcessor!
    var stateService: MockStateService!
    var environmentService: MockEnvironmentService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        authRepository = MockAuthRepository()
        captchaService = MockCaptchaService()
        client = MockHTTPClient()
        authClient = MockAuthClient()
        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        delegate = MockStartRegistrationDelegate()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()

        subject = StartRegistrationProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                captchaService: captchaService,
                clientService: MockClientService(auth: authClient),
                environmentService: environmentService,
                errorReporter: errorReporter,
                httpClient: client,
                stateService: stateService
            ),
            state: StartRegistrationState()
        )
    }

    override func tearDown() {
        super.tearDown()
        authRepository = nil
        captchaService = nil
        authClient = nil
        client = nil
        coordinator = nil
        environmentService = nil
        errorReporter = nil
        subject = nil
        stateService = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.regionTapped` navigates to the region selection screen.
    @MainActor
    func test_perform_regionTapped() async throws {
        await subject.perform(.regionTapped)

        var alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, Localizations.creatingOn)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions.count, 4)

        XCTAssertEqual(alert.alertActions[0].title, "bitwarden.com")
        try await alert.tapAction(title: "bitwarden.com")
        XCTAssertEqual(subject.state.region, .unitedStates)

        await subject.perform(.regionTapped)
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.alertActions[1].title, "bitwarden.eu")
        try await alert.tapAction(title: "bitwarden.eu")
        XCTAssertEqual(subject.state.region, .europe)

        await subject.perform(.regionTapped)
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.selfHosted)
        try await alert.tapAction(title: Localizations.selfHosted)
        XCTAssertEqual(coordinator.routes.last, .selfHosted(currentRegion: .europe))
    }

    /// `perform(_:)` with `.startRegistration` sets preAuthUrls for the given email and navigates to check email.
    @MainActor
    func test_perform_startRegistration_setPreAuthUrls_checkEmail() async throws {
        subject.state = .fixture()
        client.result = .httpSuccess(testData: .nilResponse)
        stateService.preAuthEnvironmentURLs = .defaultEU

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(
            client.requests[0].url,
            URL(string: "https://example.com/identity/accounts/register/send-verification-email")
        )
        XCTAssertEqual(coordinator.routes.last, .checkEmail(
            email: "example@email.com"
        ))

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(
            coordinator.loadingOverlaysShown,
            [
                LoadingOverlayState(title: Localizations.creatingAccount),
            ]
        )
        XCTAssertEqual(stateService.accountCreationEnvironmentURLs["example@email.com"], .defaultEU)
    }

    /// `perform(_:)` with `.startRegistration` sets preAuthUrls for the given email and navigates to check email.
    @MainActor
    func test_perform_startRegistration_setPreAuthUrls_checkEmail_emailWithSpaceAndCapitals() async throws {
        subject.state = .fixture(emailText: "  example@EMAIL.com   ")
        client.result = .httpSuccess(testData: .nilResponse)
        stateService.preAuthEnvironmentURLs = .defaultEU

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(
            client.requests[0].url,
            URL(string: "https://example.com/identity/accounts/register/send-verification-email")
        )
        XCTAssertEqual(coordinator.routes.last, .checkEmail(
            email: "example@email.com"
        ))

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(
            coordinator.loadingOverlaysShown,
            [
                LoadingOverlayState(title: Localizations.creatingAccount),
            ]
        )
        XCTAssertEqual(stateService.accountCreationEnvironmentURLs["example@email.com"], .defaultEU)
    }

    /// `perform(_:)` with `.startRegistration` fails if preAuthUrls cannot be loaded.
    @MainActor
    func test_perform_startRegistration_setPreAuthUrls_checkEmail_noUrls() async throws {
        subject.state = .fixture()
        client.result = .httpSuccess(testData: .nilResponse)
        stateService.preAuthEnvironmentURLs = nil

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(
            client.requests[0].url,
            URL(string: "https://example.com/identity/accounts/register/send-verification-email")
        )
        XCTAssertEqual(
            coordinator.alertShown.last,
            .defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.thePreAuthUrlsCouldNotBeLoadedToStartTheAccountCreation
            )
        )

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(
            coordinator.loadingOverlaysShown,
            [
                LoadingOverlayState(title: Localizations.creatingAccount),
            ]
        )
    }

    /// `perform(_:)` with `.startRegistration` presents an alert when the email has already been taken.
    @MainActor
    func test_perform_startRegistration_emailExists() async {
        subject.state = .fixture()

        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.startRegistrationEmailAlreadyExists.data
        )

        guard let errorResponse = try? ErrorResponseModel(response: response) else { return }
        let error = ServerError.error(errorResponse: errorResponse)
        client.result = .httpFailure(error)

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(coordinator.errorAlertsWithRetryShown.last?.error as? ServerError, error)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
    }

    /// `perform(_:)` with `.startRegistration` presents an alert when the email exceeds the maximum length.
    @MainActor
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
        let error = ServerError.error(errorResponse: errorResponse)
        client.result = .httpFailure(error)

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(coordinator.errorAlertsWithRetryShown.last?.error as? ServerError, error)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
    }

    /// `perform(_:)` with `.startRegistration` presents an alert when the email field is empty.
    @MainActor
    func test_perform_startRegistration_emptyEmail() async {
        subject.state = .fixture(emailText: "")

        client.result = .httpSuccess(testData: .startRegistrationSuccess)

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 0)
        XCTAssertEqual(coordinator.alertShown.last, .validationFieldRequired(fieldName: "Email"))
        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
    }

    /// `perform(_:)` with `.startRegistration` should not send name field in request body if the name is empty.
    @MainActor
    func test_perform_startRegistration_emptyName() async throws {
        subject.state = .fixture(nameText: "")

        client.result = .httpSuccess(testData: .startRegistrationSuccess)

        await subject.perform(.startRegistration)

        let requestBody = try XCTUnwrap(client.requests.first?.body)
        let requestBodyStr = try XCTUnwrap(String(data: requestBody, encoding: .utf8))
        XCTAssertFalse(
            requestBodyStr.contains("name"),
            "Request body should not contain 'name' field when it is empty."
        )
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(coordinator.alertShown.last)
        XCTAssertFalse(coordinator.loadingOverlaysShown.isEmpty)
    }

    /// `perform(_:)` with `.startRegistration` presents an alert when the email is in an invalid format.
    @MainActor
    func test_perform_startRegistration_invalidEmailFormat() async {
        subject.state = .fixture(emailText: "∫@ø.com")

        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.startRegistrationInvalidEmailFormat.data
        )

        guard let errorResponse = try? ErrorResponseModel(response: response) else { return }
        let error = ServerError.error(errorResponse: errorResponse)
        client.result = .httpFailure(error)

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(coordinator.errorAlertsWithRetryShown.last?.error as? ServerError, error)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
    }

    /// `perform(_:)` with `.startRegistration` presents an alert when there is no internet connection.
    /// When the user taps `Try again`, the create account request is made again.
    @MainActor
    func test_perform_startRegistration_noInternetConnection() async throws {
        subject.state = .fixture()

        let urlError = URLError(.notConnectedToInternet)
        client.results = [.httpFailure(urlError), .httpSuccess(testData: .startRegistrationSuccess)]

        await subject.perform(.startRegistration)

        let errorAlertWithRetry = try XCTUnwrap(coordinator.errorAlertsWithRetryShown.last)
        XCTAssertEqual(errorAlertWithRetry.error as? URLError, urlError)

        await errorAlertWithRetry.retry()

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(
            client.requests[0].url,
            URL(string: "https://example.com/identity/accounts/register/send-verification-email")
        )
        XCTAssertEqual(
            client.requests[1].url,
            URL(string: "https://example.com/identity/accounts/register/send-verification-email")
        )
        XCTAssertEqual(coordinator.routes.last, .completeRegistration(
            emailVerificationToken: "0018A45C4D1DEF81644B54AB7F969B88D65\n",
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
    @MainActor
    func test_perform_startRegistration_timeout() async throws {
        subject.state = .fixture()

        let urlError = URLError(.timedOut)
        client.results = [.httpFailure(urlError), .httpSuccess(testData: .startRegistrationSuccess)]

        await subject.perform(.startRegistration)

        let errorAlertWithRetry = try XCTUnwrap(coordinator.errorAlertsWithRetryShown.last)
        XCTAssertEqual(errorAlertWithRetry.error as? URLError, urlError)

        await errorAlertWithRetry.retry()

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(
            client.requests[0].url,
            URL(string: "https://example.com/identity/accounts/register/send-verification-email")
        )
        XCTAssertEqual(
            client.requests[1].url,
            URL(string: "https://example.com/identity/accounts/register/send-verification-email")
        )
        XCTAssertEqual(coordinator.routes.last, .completeRegistration(
            emailVerificationToken: "0018A45C4D1DEF81644B54AB7F969B88D65\n",
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
    @MainActor
    func test_perform_startRegistration_withInvalidEmail() async {
        subject.state = .fixture(emailText: "exampleemail.com")

        client.result = .httpFailure(StartRegistrationError.invalidEmail)

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 0)
        XCTAssertEqual(coordinator.alertShown.last, .invalidEmail)
        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
    }

    /// `perform(_:)` with `.startRegistration` and a valid email creates the user's account.
    @MainActor
    func test_perform_startRegistration_withValidEmail() async {
        subject.state = .fixture()

        client.result = .httpSuccess(testData: .startRegistrationSuccess)

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(
            client.requests[0].url,
            URL(string: "https://example.com/identity/accounts/register/send-verification-email")
        )

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
        XCTAssertEqual(
            coordinator.routes,
            [
                .completeRegistration(
                    emailVerificationToken: "0018A45C4D1DEF81644B54AB7F969B88D65\n",
                    userEmail: "example@email.com"
                ),
            ]
        )
    }

    /// `perform(_:)` with `.startRegistration` and a valid email surrounded by whitespace trims the whitespace and
    /// creates the user's account
    @MainActor
    func test_perform_startRegistration_withValidEmailAndSpace() async {
        subject.state = .fixture(emailText: " email@example.com ")

        client.result = .httpSuccess(testData: .startRegistrationSuccess)

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(
            client.requests[0].url,
            URL(string: "https://example.com/identity/accounts/register/send-verification-email")
        )

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
        XCTAssertEqual(
            coordinator.routes,
            [
                .completeRegistration(
                    emailVerificationToken: "0018A45C4D1DEF81644B54AB7F969B88D65\n",
                    userEmail: "email@example.com"
                ),
            ]
        )
    }

    /// `perform(_:)` with `.startRegistration` and a valid email with uppercase characters
    /// converts the email to lowercase
    /// and creates the user's account.
    @MainActor
    func test_perform_startRegistration_withValidEmailUppercased() async {
        subject.state = .fixture(emailText: "EMAIL@EXAMPLE.COM")

        client.result = .httpSuccess(testData: .startRegistrationSuccess)

        await subject.perform(.startRegistration)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(
            client.requests[0].url,
            URL(string: "https://example.com/identity/accounts/register/send-verification-email")
        )
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
        XCTAssertEqual(
            coordinator.routes,
            [
                .completeRegistration(
                    emailVerificationToken: "0018A45C4D1DEF81644B54AB7F969B88D65\n",
                    userEmail: "email@example.com"
                ),
            ]
        )
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.emailTextChanged(_:)` updates the state to reflect the change.
    @MainActor
    func test_receive_emailTextChanged() {
        subject.state.emailText = ""
        XCTAssertTrue(subject.state.emailText.isEmpty)

        subject.receive(.emailTextChanged("updated email"))
        XCTAssertTrue(subject.state.emailText == "updated email")
    }

    /// `receive(_:)` with `.toggleReceiveMarketing(_:)` updates the state to reflect the change.
    @MainActor
    func test_receive_toggleTermsAndPrivacy() {
        subject.receive(.toggleReceiveMarketing(false))
        XCTAssertFalse(subject.state.isReceiveMarketingToggleOn)

        subject.receive(.toggleReceiveMarketing(true))
        XCTAssertTrue(subject.state.isReceiveMarketingToggleOn)

        subject.receive(.toggleReceiveMarketing(true))
        XCTAssertTrue(subject.state.isReceiveMarketingToggleOn)
    }

    /// `didSaveEnvironment(urls:)` with URLs sets the region to self-hosted and sets the URLs in
    /// the environment.
    @MainActor
    func test_didSaveEnvironment() async {
        subject.state.region = .unitedStates
        await subject.didSaveEnvironment(urls: EnvironmentURLData(base: .example))
        XCTAssertEqual(subject.state.region, .selfHosted)
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.environmentSaved))
        XCTAssertEqual(
            environmentService.setPreAuthEnvironmentURLsData,
            EnvironmentURLData(base: .example)
        )
    }

    /// `didSaveEnvironment(urls:)` with empty URLs doesn't change the region or the environment URLs.
    @MainActor
    func test_didSaveEnvironment_empty() async {
        subject.state.region = .unitedStates
        await subject.didSaveEnvironment(urls: EnvironmentURLData())
        XCTAssertEqual(subject.state.region, .unitedStates)
        XCTAssertNil(environmentService.setPreAuthEnvironmentURLsData)
    }

    /// `perform(.appeared)` with no pre-auth URLs defaults the region and URLs to the US environment.
    @MainActor
    func test_perform_appeared_loadsRegion_noPreAuthUrls() async {
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .unitedStates)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentURLsData, .defaultUS)
    }

    /// `perform(.appeared)` with EU pre-auth URLs sets the state to the EU region and sets the
    /// environment URLs.
    @MainActor
    func test_perform_appeared_loadsRegion_withPreAuthUrls_europe() async {
        stateService.preAuthEnvironmentURLs = .defaultEU
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .europe)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentURLsData, .defaultEU)
    }

    /// `perform(.appeared)` with self-hosted pre-auth URLs sets the state to the self-hosted region
    /// and sets the URLs to the environment.
    @MainActor
    func test_perform_appeared_loadsRegion_withPreAuthUrls_selfHosted() async {
        let urls = EnvironmentURLData(base: .example)
        stateService.preAuthEnvironmentURLs = urls
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .selfHosted)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentURLsData, urls)
    }

    /// `perform(.appeared)` with US pre-auth URLs sets the state to the US region and sets the
    /// environment URLs.
    @MainActor
    func test_perform_appeared_loadsRegion_withPreAuthUrls_unitedStates() async {
        stateService.preAuthEnvironmentURLs = .defaultUS
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .unitedStates)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentURLsData, .defaultUS)
    }

    /// `perform(.appeared)` with US pre-auth URLs sets the state to the US region and sets the
    /// environment URLs.
    /// Test if isReceiveMarketingToggle is On
    @MainActor
    func test_perform_appeared_loadsRegion_withPreAuthUrls_unitedStates_isReceiveMarketingToggle_on() async {
        stateService.preAuthEnvironmentURLs = .defaultUS
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .unitedStates)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentURLsData, .defaultUS)
        XCTAssertTrue(subject.state.isReceiveMarketingToggleOn)
    }

    /// `perform(.appeared)` with EU pre-auth URLs sets the state to the EU region and sets the
    /// environment URLs.
    /// Test if isReceiveMarketingToggle is Off
    @MainActor
    func test_perform_appeared_loadsRegion_withPreAuthUrls_europe_isReceiveMarketingToggle_off() async {
        stateService.preAuthEnvironmentURLs = .defaultEU
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .europe)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentURLsData, .defaultEU)
        XCTAssertFalse(subject.state.isReceiveMarketingToggleOn)
    }
}

class MockStartRegistrationDelegate: StartRegistrationDelegate {
    var didChangeRegionCalled: Bool = false

    func didChangeRegion() async {
        didChangeRegionCalled = true
    }
} // swiftlint:disable:this file_length
