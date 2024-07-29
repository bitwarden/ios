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
    var stateService: MockStateService!
    var environmentService: MockEnvironmentService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        authRepository = MockAuthRepository()
        captchaService = MockCaptchaService()
        client = MockHTTPClient()
        clientAuth = MockClientAuth()
        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()

        subject = StartRegistrationProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                captchaService: captchaService,
                clientService: MockClientService(auth: clientAuth),
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
        clientAuth = nil
        client = nil
        coordinator = nil
        environmentService = nil
        errorReporter = nil
        subject = nil
        stateService = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.regionTapped` navigates to the region selection screen.
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
    func test_perform_startRegistration_timeout() async throws {
        subject.state = .fixture()

        let urlError = URLError(.timedOut) as Error
        client.results = [.httpFailure(urlError), .httpSuccess(testData: .startRegistrationSuccess)]

        await subject.perform(.startRegistration)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.message, urlError.localizedDescription)

        try await alert.tapAction(title: Localizations.tryAgain)

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
        XCTAssertEqual(
            client.requests[0].url,
            URL(string: "https://example.com/identity/accounts/register/send-verification-email")
        )

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
        XCTAssertEqual(
            client.requests[0].url,
            URL(string: "https://example.com/identity/accounts/register/send-verification-email")
        )

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
        XCTAssertEqual(
            client.requests[0].url,
            URL(string: "https://example.com/identity/accounts/register/send-verification-email")
        )
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.creatingAccount)])
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

    /// `receive(_:)` with `.toggleReceiveMarketing(_:)` updates the state to reflect the change.
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
    func test_didSaveEnvironment() async {
        subject.state.region = .unitedStates
        await subject.didSaveEnvironment(urls: EnvironmentUrlData(base: .example))
        XCTAssertEqual(subject.state.region, .selfHosted)
        XCTAssertEqual(subject.state.toast?.text, Localizations.environmentSaved)
        XCTAssertEqual(
            environmentService.setPreAuthEnvironmentUrlsData,
            EnvironmentUrlData(base: .example)
        )
    }

    /// `didSaveEnvironment(urls:)` with empty URLs doesn't change the region or the environment URLs.
    func test_didSaveEnvironment_empty() async {
        subject.state.region = .unitedStates
        await subject.didSaveEnvironment(urls: EnvironmentUrlData())
        XCTAssertEqual(subject.state.region, .unitedStates)
        XCTAssertNil(environmentService.setPreAuthEnvironmentUrlsData)
    }

    /// `perform(.appeared)` with no pre-auth URLs defaults the region and URLs to the US environment.
    func test_perform_appeared_loadsRegion_noPreAuthUrls() async {
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .unitedStates)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentUrlsData, .defaultUS)
    }

    /// `perform(.appeared)` with EU pre-auth URLs sets the state to the EU region and sets the
    /// environment URLs.
    func test_perform_appeared_loadsRegion_withPreAuthUrls_europe() async {
        stateService.preAuthEnvironmentUrls = .defaultEU
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .europe)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentUrlsData, .defaultEU)
    }

    /// `perform(.appeared)` with self-hosted pre-auth URLs sets the state to the self-hosted region
    /// and sets the URLs to the environment.
    func test_perform_appeared_loadsRegion_withPreAuthUrls_selfHosted() async {
        let urls = EnvironmentUrlData(base: .example)
        stateService.preAuthEnvironmentUrls = urls
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .selfHosted)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentUrlsData, urls)
    }

    /// `perform(.appeared)` with US pre-auth URLs sets the state to the US region and sets the
    /// environment URLs.
    func test_perform_appeared_loadsRegion_withPreAuthUrls_unitedStates() async {
        stateService.preAuthEnvironmentUrls = .defaultUS
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .unitedStates)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentUrlsData, .defaultUS)
    }

    /// `perform(.appeared)` with US pre-auth URLs sets the state to the US region and sets the
    /// environment URLs.
    /// Test if isReceiveMarketingToggle is On
    func test_perform_appeared_loadsRegion_withPreAuthUrls_unitedStates_isReceiveMarketingToggle_on() async {
        stateService.preAuthEnvironmentUrls = .defaultUS
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .unitedStates)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentUrlsData, .defaultUS)
        XCTAssertTrue(subject.state.isReceiveMarketingToggleOn)
    }

    /// `perform(.appeared)` with EU pre-auth URLs sets the state to the EU region and sets the
    /// environment URLs.
    /// Test if isReceiveMarketingToggle is Off
    func test_perform_appeared_loadsRegion_withPreAuthUrls_europe_isReceiveMarketingToggle_off() async {
        stateService.preAuthEnvironmentUrls = .defaultEU
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .europe)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentUrlsData, .defaultEU)
        XCTAssertFalse(subject.state.isReceiveMarketingToggleOn)
    }
}

class MockStartRegistrationDelegate: StartRegistrationDelegate {
    var didChangeRegionCalled: Bool = false

    func didChangeRegion() async {
        didChangeRegionCalled = true
    }
} // swiftlint:disable:this file_length
