import XCTest

@testable import BitwardenShared

class SingleSignOnProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authService: MockAuthService!
    var client: MockHTTPClient!
    var coordinator: MockCoordinator<AuthRoute>!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: SingleSignOnProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        authService = MockAuthService()
        client = MockHTTPClient()
        coordinator = MockCoordinator<AuthRoute>()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        let services = ServiceContainer.withMocks(
            authService: authService,
            errorReporter: errorReporter,
            httpClient: client,
            stateService: stateService
        )

        subject = SingleSignOnProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: SingleSignOnState()
        )
    }

    override func tearDown() {
        super.tearDown()

        authService = nil
        client = nil
        coordinator = nil
        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.loadSingleSignOnDetails` records an error if the API call failed.
    func test_perform_loadSingleSignOnDetails_error() async throws {
        client.result = .failure(BitwardenTestError.example)
        stateService.rememberedOrgIdentifier = "BestOrganization"

        await subject.perform(.loadSingleSignOnDetails)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown.last, LoadingOverlayState(title: Localizations.loading))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)

        XCTAssertEqual(subject.state.identifierText, "BestOrganization")
    }

    /// `perform(_:)` with `.loadSingleSignOnDetails` starts the login process if the API call
    /// returns a valid organization identifier.
    func test_perform_loadSingleSignOnDetails_success() async throws {
        client.result = .httpSuccess(testData: .singleSignOnDetails)

        await subject.perform(.loadSingleSignOnDetails)

        XCTAssertEqual(coordinator.loadingOverlaysShown.first, LoadingOverlayState(title: Localizations.loading))
        XCTAssertEqual(coordinator.loadingOverlaysShown.last, LoadingOverlayState(title: Localizations.loggingIn))
        XCTAssertEqual(coordinator.loadingOverlaysShown.last, LoadingOverlayState(title: Localizations.loggingIn))
        XCTAssertEqual(
            coordinator.routes.last,
            .singleSignOn(callbackUrlScheme: "callback", state: "state", url: .example)
        )
    }

    /// `perform(_:)` with `.loginPressed` displays an alert if organization identifier field is invalid.
    func test_perform_loginPressed_invalidIdentifier() async throws {
        subject.state.identifierText = "    "

        await subject.perform(.loginTapped)

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.validationFieldRequired(Localizations.orgIdentifier),
                alertActions: [AlertAction(title: Localizations.ok, style: .default)]
            )
        )
    }

    /// `perform(_:)` with `.loginPressed` handles errors correctly.
    func test_perform_loginPressed_error() async throws {
        // Set up the mock data.
        authService.generateSingleSignOnUrlResult = .failure(URLError(.timedOut))
        subject.state.identifierText = "BestOrganization"

        // Attempt to log in.
        await subject.perform(.loginTapped)

        // Verify the results.
        XCTAssertEqual(authService.generateSingleSignOnOrgIdentifier, "BestOrganization")
        XCTAssertEqual(coordinator.loadingOverlaysShown.last, LoadingOverlayState(title: Localizations.loggingIn))
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(URLError(.timedOut)) {})
        XCTAssertEqual(errorReporter.errors.last as? URLError, URLError(.timedOut))
    }

    /// `perform(_:)` with `.loginPressed` attempts to login.
    func test_perform_loginPressed_success() async throws {
        // Set up the mock data.
        subject.state.identifierText = "BestOrganization"

        // Attempt to log in.
        await subject.perform(.loginTapped)

        // Verify the results.
        XCTAssertEqual(coordinator.loadingOverlaysShown.last, LoadingOverlayState(title: Localizations.loggingIn))
        XCTAssertEqual(
            coordinator.routes.last,
            .singleSignOn(callbackUrlScheme: "callback", state: "state", url: .example)
        )
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.identifierTextChanged(_:)` updates the state.
    func test_receive_identifierTextChanged() {
        subject.state.identifierText = ""
        XCTAssertTrue(subject.state.identifierText.isEmpty)

        subject.receive(.identifierTextChanged("updated name"))
        XCTAssertTrue(subject.state.identifierText == "updated name")
    }

    /// `singleSignOnCompleted(code:)` handles any errors correctly.
    func test_singleSignOnCompleted_error() {
        // Set up the mock data.
        authService.loginWithSingleSignOnResult = .failure(BitwardenTestError.example)

        // Receive the completed code.
        subject.singleSignOnCompleted(code: "super_cool_secret_code")
        waitFor(!errorReporter.errors.isEmpty)

        // Verify the results.
        XCTAssertEqual(authService.loginWithSingleSignOnCode, "super_cool_secret_code")
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(BitwardenTestError.example))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `singleSignOnCompleted(code:)` navigates to the two-factor view if two-factor authentication is needed.
    func test_singleSignOnCompleted_twoFactorError() async throws {
        // Set up the mock data.
        let authMethodsData = [String: [String: String]]()
        authService.generateSingleSignOnUrlResult = .failure(
            IdentityTokenRequestError.twoFactorRequired(authMethodsData, nil)
        )
        subject.state.identifierText = "BestOrganization"

        await subject.perform(.loginTapped)

        // Verify the results.
        XCTAssertEqual(coordinator.routes.last, .twoFactor("", nil, authMethodsData))
    }

    /// `singleSignOnCompleted(code:)` navigates to the vault unlock view if the vault is still locked.
    func test_singleSignOnCompleted_vaultLocked() {
        // Set up the mock data.
        authService.loginWithSingleSignOnResult = .success(.fixtureAccountLogin())
        subject.state.identifierText = "BestOrganization"

        // Receive the completed code.
        subject.singleSignOnCompleted(code: "super_cool_secret_code")
        waitFor(!coordinator.routes.isEmpty)

        // Verify the results.
        XCTAssertEqual(authService.loginWithSingleSignOnCode, "super_cool_secret_code")
        XCTAssertEqual(stateService.rememberedOrgIdentifier, "BestOrganization")
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(
            coordinator.routes,
            [
                .vaultUnlock(
                    .fixtureAccountLogin(),
                    animated: false,
                    attemptAutomaticBiometricUnlock: true
                ),
                .dismiss,
            ]
        )
    }

    /// `singleSignOnCompleted(code:)` navigates to the complete route if the vault is unlocked.
    func test_singleSignOnCompleted_vaultUnlocked() {
        // Set up the mock data.
        authService.loginWithSingleSignOnResult = .success(nil)
        subject.state.identifierText = "BestOrganization"

        // Receive the completed code.
        subject.singleSignOnCompleted(code: "super_cool_secret_code")
        waitFor(!coordinator.routes.isEmpty)

        // Verify the results.
        XCTAssertEqual(authService.loginWithSingleSignOnCode, "super_cool_secret_code")
        XCTAssertEqual(stateService.rememberedOrgIdentifier, "BestOrganization")
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.routes, [.complete, .dismiss])
    }

    /// `singleSignOnErrored(error:)` handles the error correctly.
    func test_singleSignOnErrored() {
        subject.singleSignOnErrored(error: BitwardenTestError.example)
        waitFor(!errorReporter.errors.isEmpty)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(BitwardenTestError.example))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }
}
