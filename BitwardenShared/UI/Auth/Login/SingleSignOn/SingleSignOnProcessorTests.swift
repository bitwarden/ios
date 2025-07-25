import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

@testable import BitwardenShared

class SingleSignOnProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var authService: MockAuthService!
    var client: MockHTTPClient!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: SingleSignOnProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        authService = MockAuthService()
        client = MockHTTPClient()
        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        let services = ServiceContainer.withMocks(
            authRepository: authRepository,
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

        authRepository = nil
        authService = nil
        client = nil
        coordinator = nil
        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.loadSingleSignOnDetails` records an error if getting the org id throws.
    @MainActor
    func test_perform_loadSingleSignOnDetails_error() async throws {
        authRepository.getSSOOrganizationIdentifierByResult = .failure(BitwardenTestError.example)

        await subject.perform(.loadSingleSignOnDetails)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown.last, LoadingOverlayState(title: Localizations.loading))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)

        XCTAssertEqual(subject.state.identifierText, "")
    }

    /// `perform(_:)` with `.loadSingleSignOnDetails` records an error if getting the org id throws
    /// and loads the last used organization identifier.
    @MainActor
    func test_perform_loadSingleSignOnDetails_errorRememberedOrgId() async throws {
        authRepository.getSSOOrganizationIdentifierByResult = .failure(BitwardenTestError.example)
        stateService.rememberedOrgIdentifier = "BestOrganization"

        await subject.perform(.loadSingleSignOnDetails)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown.last, LoadingOverlayState(title: Localizations.loading))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)

        XCTAssertEqual(subject.state.identifierText, "BestOrganization")
    }

    /// `perform(_:)` with `.loadSingleSignOnDetails` starts the login process if the organization identifier
    /// is not `nil`.
    @MainActor
    func test_perform_loadSingleSignOnDetails_success() async throws {
        authRepository.getSSOOrganizationIdentifierByResult = .success("OrgId")

        await subject.perform(.loadSingleSignOnDetails)

        XCTAssertEqual(coordinator.loadingOverlaysShown.first, LoadingOverlayState(title: Localizations.loading))
        XCTAssertEqual(coordinator.loadingOverlaysShown.last, LoadingOverlayState(title: Localizations.loggingIn))
        XCTAssertEqual(coordinator.loadingOverlaysShown.last, LoadingOverlayState(title: Localizations.loggingIn))
        XCTAssertEqual(
            coordinator.routes.last,
            .singleSignOn(callbackUrlScheme: "callback", state: "state", url: .example)
        )
        XCTAssertEqual(subject.state.identifierText, "OrgId")
    }

    /// `perform(_:)` with `.loadSingleSignOnDetails` doesn't start the login process
    /// if the organization identifier is `nil`.
    @MainActor
    func test_perform_loadSingleSignOnDetails_orgIdNil() async throws {
        authRepository.getSSOOrganizationIdentifierByResult = .success(nil)

        await subject.perform(.loadSingleSignOnDetails)

        XCTAssertEqual(coordinator.loadingOverlaysShown.first, LoadingOverlayState(title: Localizations.loading))
        XCTAssertNotEqual(coordinator.loadingOverlaysShown.last, LoadingOverlayState(title: Localizations.loggingIn))
        XCTAssertNotEqual(coordinator.loadingOverlaysShown.last, LoadingOverlayState(title: Localizations.loggingIn))
        XCTAssertNotEqual(
            coordinator.routes.last,
            .singleSignOn(callbackUrlScheme: "callback", state: "state", url: .example)
        )
        XCTAssertEqual(subject.state.identifierText, "")
    }

    /// `perform(_:)` with `.loadSingleSignOnDetails` doesn't start the login process
    /// if the organization identifier is `nil`, but populates the organization identifier with the
    /// last used identifier.
    @MainActor
    func test_perform_loadSingleSignOnDetails_orgIdNilRememberedOrgId() async throws {
        authRepository.getSSOOrganizationIdentifierByResult = .success(nil)
        stateService.rememberedOrgIdentifier = "BestOrganization"

        await subject.perform(.loadSingleSignOnDetails)

        XCTAssertEqual(coordinator.loadingOverlaysShown.first, LoadingOverlayState(title: Localizations.loading))
        XCTAssertNotEqual(coordinator.loadingOverlaysShown.last, LoadingOverlayState(title: Localizations.loggingIn))
        XCTAssertNotEqual(coordinator.loadingOverlaysShown.last, LoadingOverlayState(title: Localizations.loggingIn))
        XCTAssertNotEqual(
            coordinator.routes.last,
            .singleSignOn(callbackUrlScheme: "callback", state: "state", url: .example)
        )
        XCTAssertEqual(subject.state.identifierText, "BestOrganization")
    }

    /// `perform(_:)` with `.loadSingleSignOnDetails` loads the SSO organization identifier even if
    /// there's a remembered org identifier.
    @MainActor
    func test_perform_loadSingleSignOnDetails_successWithRememberedOrgId() async throws {
        authRepository.getSSOOrganizationIdentifierByResult = .success("OrgId")
        stateService.rememberedOrgIdentifier = "SSO"

        await subject.perform(.loadSingleSignOnDetails)

        XCTAssertEqual(
            coordinator.loadingOverlaysShown,
            [
                LoadingOverlayState(title: Localizations.loading),
                LoadingOverlayState(title: Localizations.loggingIn),
            ]
        )
        XCTAssertEqual(
            coordinator.routes.last,
            .singleSignOn(callbackUrlScheme: "callback", state: "state", url: .example)
        )
        XCTAssertEqual(subject.state.identifierText, "OrgId")
    }

    /// `perform(_:)` with `.loginPressed` displays an alert if organization identifier field is invalid.
    @MainActor
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
    @MainActor
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
        XCTAssertEqual(coordinator.errorAlertsWithRetryShown.last?.error as? URLError, URLError(.timedOut))
        XCTAssertEqual(errorReporter.errors.last as? URLError, URLError(.timedOut))
    }

    /// `perform(_:)` with `.loginPressed` attempts to login.
    @MainActor
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
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.identifierTextChanged(_:)` updates the state.
    @MainActor
    func test_receive_identifierTextChanged() {
        subject.state.identifierText = ""
        XCTAssertTrue(subject.state.identifierText.isEmpty)

        subject.receive(.identifierTextChanged("updated name"))
        XCTAssertTrue(subject.state.identifierText == "updated name")
    }

    /// `singleSignOnCompleted(code:)` handles any errors correctly.
    @MainActor
    func test_singleSignOnCompleted_error() {
        // Set up the mock data.
        authService.loginWithSingleSignOnResult = .failure(BitwardenTestError.example)

        // Receive the completed code.
        subject.singleSignOnCompleted(code: "super_cool_secret_code")
        waitFor(!errorReporter.errors.isEmpty)

        // Verify the results.
        XCTAssertEqual(authService.loginWithSingleSignOnCode, "super_cool_secret_code")
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
        XCTAssertNil(stateService.rememberedOrgIdentifier)
    }

    /// `singleSignOnCompleted(code:)` navigates to the two-factor view if two-factor authentication is needed.
    @MainActor
    func test_singleSignOnCompleted_twoFactorError() async throws {
        // Set up the mock data.
        authService.generateSingleSignOnUrlResult = .failure(
            IdentityTokenRequestError.twoFactorRequired(AuthMethodsData(), nil, nil, nil)
        )
        subject.state.identifierText = "BestOrganization"

        await subject.perform(.loginTapped)

        // Verify the results.
        XCTAssertEqual(coordinator.routes.last, .twoFactor("", nil, AuthMethodsData(), "BestOrganization"))
        XCTAssertEqual(stateService.rememberedOrgIdentifier, "BestOrganization")
    }

    /// `singleSignOnCompleted(code:)` navigates to the set password screen if the user needs
    /// to set a master password.
    @MainActor
    func test_singleSignOnCompleted_requireSetPasswordError() {
        authService.loginWithSingleSignOnResult = .failure(AuthError.requireSetPassword)
        subject.state.identifierText = "BestOrganization"

        subject.singleSignOnCompleted(code: "CODE")

        waitFor(!coordinator.routes.isEmpty)

        XCTAssertEqual(coordinator.routes, [.setMasterPassword(organizationIdentifier: "BestOrganization")])
        XCTAssertEqual(stateService.rememberedOrgIdentifier, "BestOrganization")
    }

    /// `singleSignOnCompleted(code:)` navigates to the update password screen if the user needs
    /// to update their master password.
    @MainActor
    func test_singleSignOnCompleted_requireUpdatePasswordError() {
        authService.loginWithSingleSignOnResult = .failure(AuthError.requireUpdatePassword)
        subject.state.identifierText = "BestOrganization"

        subject.singleSignOnCompleted(code: "CODE")

        waitFor(!coordinator.routes.isEmpty)

        XCTAssertEqual(coordinator.routes, [.updateMasterPassword])
        XCTAssertEqual(stateService.rememberedOrgIdentifier, "BestOrganization")
    }

    /// `singleSignOnCompleted(code:)` navigates to the show login decryption options screen if the
    /// user needs to choose their decryption option for login.
    @MainActor
    func test_singleSignOnCompleted_requireDecryptionOptionsError() {
        authService.loginWithSingleSignOnResult = .failure(AuthError.requireDecryptionOptions)
        subject.state.identifierText = "BestOrganization"

        subject.singleSignOnCompleted(code: "CODE")

        waitFor(!coordinator.routes.isEmpty)

        XCTAssertEqual(coordinator.routes, [.showLoginDecryptionOptions(organizationIdentifier: "BestOrganization")])
        XCTAssertEqual(stateService.rememberedOrgIdentifier, "BestOrganization")
    }

    /// `singleSignOnCompleted(code:)` navigates to the vault unlock view if the vault is still locked.
    @MainActor
    func test_singleSignOnCompleted_vaultLocked() {
        // Set up the mock data.
        authService.loginWithSingleSignOnResult = .success(.masterPassword(.fixtureAccountLogin()))
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
                    attemptAutomaticBiometricUnlock: true,
                    didSwitchAccountAutomatically: false
                ),
                .dismiss,
            ]
        )
    }

    /// `singleSignOnCompleted(code:)` navigates to the complete route if the user uses Key Connector.
    @MainActor
    func test_singleSignOnCompleted_vaultUnlockedKeyConnector() {
        // Set up the mock data.
        authService.loginWithSingleSignOnResult = .success(.keyConnector(
            keyConnectorURL: URL(string: "https://example.com")!
        ))
        subject.state.identifierText = "BestOrganization"

        // Receive the completed code.
        subject.singleSignOnCompleted(code: "super_cool_secret_code")
        waitFor(!coordinator.routes.isEmpty)

        // Verify the results.
        XCTAssertTrue(authRepository.unlockVaultWithKeyConnectorKeyCalled)
        XCTAssertEqual(authService.loginWithSingleSignOnCode, "super_cool_secret_code")
        XCTAssertEqual(stateService.rememberedOrgIdentifier, "BestOrganization")
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.events.last, .didCompleteAuth)
        XCTAssertEqual(coordinator.routes, [.dismiss])
    }

    /// `singleSignOnCompleted(code:)` show confirm key connector dialog
    /// if user has no private key and uses Key Connector.
    @MainActor
    func test_singleSignOnCompleted_vaultUnlockedKeyConnector_noPrivateKey() async throws {
        // Set up the mock data.
        authService.loginWithSingleSignOnResult = .success(.keyConnector(
            keyConnectorURL: URL(string: "https://example.com")!
        ))
        subject.state.identifierText = "BestOrganization"
        authRepository.unlockVaultWithKeyConnectorKeyResult = .failure(StateServiceError.noEncryptedPrivateKey)

        // Receive the completed code.
        subject.singleSignOnCompleted(code: "super_cool_secret_code")
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        waitFor(!coordinator.alertShown.isEmpty)
        authRepository.unlockVaultWithKeyConnectorKeyResult = .success(())

        // Verify the results.
        XCTAssertTrue(authRepository.unlockVaultWithKeyConnectorKeyCalled)
        XCTAssertEqual(authService.loginWithSingleSignOnCode, "super_cool_secret_code")
        XCTAssertEqual(stateService.rememberedOrgIdentifier, "BestOrganization")
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        let alert = coordinator.alertShown.last
        XCTAssertEqual(alert,
                       Alert.keyConnectorConfirmation(keyConnectorUrl: URL(string: "https://example.com")!) {})

        try await alert?.tapAction(title: Localizations.yes)

        waitFor(!coordinator.routes.isEmpty)
        XCTAssertTrue(authRepository.convertNewUserToKeyConnectorKeyCalled)
        XCTAssertEqual(authRepository.convertNewUserToKeyConnectorOrgIdentifier, "BestOrganization")
        XCTAssertEqual(authRepository.convertNewUserToKeyConnectorKeyConnectorURL, URL(string: "https://example.com")!)

        XCTAssertEqual(coordinator.events.last, .didCompleteAuth)
        XCTAssertEqual(coordinator.routes, [.dismiss])
    }

    /// `singleSignOnCompleted(code:)` show confirm key connector dialog
    /// if user has no private key and uses Key Connector.
    @MainActor
    func test_singleSignOnCompleted_vaultUnlockedKeyConnector_noPrivateKey_error() async throws {
        // Set up the mock data.
        let error = BitwardenTestError.example
        authService.loginWithSingleSignOnResult = .success(.keyConnector(
            keyConnectorURL: URL(string: "https://example.com")!
        ))
        subject.state.identifierText = "BestOrganization"
        authRepository.unlockVaultWithKeyConnectorKeyResult = .failure(StateServiceError.noEncryptedPrivateKey)

        // Receive the completed code.
        subject.singleSignOnCompleted(code: "super_cool_secret_code")
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        waitFor(!coordinator.alertShown.isEmpty)
        authRepository.unlockVaultWithKeyConnectorKeyResult = .success(())
        authRepository.convertNewUserToKeyConnectorKeyResult = .failure(error)

        // Verify the results.
        XCTAssertTrue(authRepository.unlockVaultWithKeyConnectorKeyCalled)
        XCTAssertEqual(authService.loginWithSingleSignOnCode, "super_cool_secret_code")
        XCTAssertEqual(stateService.rememberedOrgIdentifier, "BestOrganization")
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        let alert = coordinator.alertShown.last
        XCTAssertEqual(alert,
                       Alert.keyConnectorConfirmation(keyConnectorUrl: URL(string: "https://example.com")!) {})

        try await alert?.tapAction(title: Localizations.yes)

        waitFor(!coordinator.errorAlertsShown.isEmpty)
        XCTAssertTrue(authRepository.convertNewUserToKeyConnectorKeyCalled)
        XCTAssertEqual(authRepository.convertNewUserToKeyConnectorOrgIdentifier, "BestOrganization")
        XCTAssertEqual(authRepository.convertNewUserToKeyConnectorKeyConnectorURL, URL(string: "https://example.com")!)

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [error])
        XCTAssertNotEqual(coordinator.events.last, .didCompleteAuth)
        XCTAssertNotEqual(coordinator.routes, [.dismiss])
    }

    /// `singleSignOnCompleted(code:)` navigates to the complete route if the user uses TDE.
    @MainActor
    func test_singleSignOnCompleted_vaultUnlockedTDE() {
        // Set up the mock data.
        authService.loginWithSingleSignOnResult = .success(.deviceKey)
        subject.state.identifierText = "BestOrganization"

        // Receive the completed code.
        subject.singleSignOnCompleted(code: "super_cool_secret_code")
        waitFor(!coordinator.routes.isEmpty)

        // Verify the results.
        XCTAssertTrue(authRepository.unlockVaultWithDeviceKeyCalled)
        XCTAssertEqual(authService.loginWithSingleSignOnCode, "super_cool_secret_code")
        XCTAssertEqual(stateService.rememberedOrgIdentifier, "BestOrganization")
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.events.last, .didCompleteAuth)
        XCTAssertEqual(coordinator.routes, [.dismiss])
    }

    /// `singleSignOnErrored(error:)` handles the error correctly.
    @MainActor
    func test_singleSignOnErrored() {
        subject.singleSignOnErrored(error: BitwardenTestError.example)
        waitFor(!errorReporter.errors.isEmpty)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }
} // swiftlint:disable:this file_length
