import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

class AccountSecurityProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var biometricsService: MockBiometricsService!
    var coordinator: MockCoordinator<SettingsRoute>!
    var errorReporter: MockErrorReporter!
    var settingsRepository: MockSettingsRepository!
    var stateService: MockStateService!
    var twoStepLoginService: MockTwoStepLoginService!
    var subject: AccountSecurityProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        biometricsService = MockBiometricsService()
        coordinator = MockCoordinator<SettingsRoute>()
        errorReporter = MockErrorReporter()
        settingsRepository = MockSettingsRepository()
        stateService = MockStateService()
        twoStepLoginService = MockTwoStepLoginService()

        subject = AccountSecurityProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                biometricsService: biometricsService,
                errorReporter: errorReporter,
                settingsRepository: settingsRepository,
                stateService: stateService,
                twoStepLoginService: twoStepLoginService
            ),
            state: AccountSecurityState()
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        biometricsService = nil
        coordinator = nil
        errorReporter = nil
        settingsRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.lockVault` locks the user's vault.
    func test_perform_lockVault() async {
        let account: Account = .fixtureAccountLogin()
        stateService.activeAccount = account

        await subject.perform(.lockVault)

        XCTAssertEqual(settingsRepository.lockVaultCalls, [account.profile.userId])
        XCTAssertEqual(coordinator.routes.last, .lockVault(account: account))
    }

    /// `perform(_:)` with `.lockVault` fails, locks the vault and navigates to the landing screen.
    func test_perform_lockVault_failure() async {
        await subject.perform(.lockVault)

        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [StateServiceError.noActiveAccount])
        XCTAssertEqual(coordinator.routes.last, .logout)
    }

    /// `perform(_:)` with `.accountFingerprintPhrasePressed` navigates to the web app
    /// and clears the fingerprint phrase URL.
    func test_perform_showAccountFingerprintPhraseAlert() async throws {
        stateService.activeAccount = .fixture()
        await subject.perform(.accountFingerprintPhrasePressed)

        let fingerprint = try authRepository.fingerprintPhraseResult.get()
        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, Localizations.fingerprintPhrase)
        XCTAssertEqual(alert.message, "\(Localizations.yourAccountsFingerprint):\n\n\(fingerprint)")
        XCTAssertEqual(alert.preferredStyle, .alert)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.close)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.learnMore)

        // Tapping learn more navigates the user to the web app.
        try await alert.tapAction(title: Localizations.learnMore)
        XCTAssertNotNil(subject.state.fingerprintPhraseUrl)

        subject.receive(.clearFingerprintPhraseUrl)
        XCTAssertNil(subject.state.fingerprintPhraseUrl)
    }

    /// `perform(_:)` with `.accountFingerprintPhrasePressed` shows an alert if an error occurs.
    func test_perform_showAccountFingerprintPhraseAlert_error() async throws {
        struct FingerprintPhraseError: Error {}

        authRepository.fingerprintPhraseResult = .failure(FingerprintPhraseError())
        await subject.perform(.accountFingerprintPhrasePressed)

        let alert = try coordinator.unwrapLastRouteAsAlert()

        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred
            )
        )
    }

    /// `receive(_:)` with `.twoStepLoginPressed` clears the two step login URL.
    func test_receive_clearTwoStepLoginUrl() async throws {
        subject.receive(.twoStepLoginPressed)

        let alert = try coordinator.unwrapLastRouteAsAlert()

        // Tapping yes navigates the user to the web app.
        try await alert.tapAction(title: Localizations.yes)
        XCTAssertNotNil(subject.state.twoStepLoginUrl)

        subject.receive(.clearTwoStepLoginUrl)
        XCTAssertNil(subject.state.twoStepLoginUrl)
    }

    /// `receive(_:)` with `.deleteAccountPressed` shows the `DeleteAccountView`.
    func test_receive_deleteAccountPressed() throws {
        subject.receive(.deleteAccountPressed)

        XCTAssertEqual(coordinator.routes.last, .deleteAccount)
    }

    /// `receive(_:)` with `.logout` presents a logout confirmation alert.
    func test_receive_logout() async throws {
        subject.receive(.logout)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, Localizations.logOut)
        XCTAssertEqual(alert.message, Localizations.logoutConfirmation)
        XCTAssertEqual(alert.preferredStyle, .alert)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        settingsRepository.logoutResult = .success(())
        // Tapping yes logs the user out.
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(coordinator.routes.last, .logout)
    }

    /// `receive(_:)` with `.logout` presents a logout confirmation alert.
    func test_receive_logout_error() async throws {
        subject.receive(.logout)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, Localizations.logOut)
        XCTAssertEqual(alert.message, Localizations.logoutConfirmation)
        XCTAssertEqual(alert.preferredStyle, .alert)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        // Tapping yes relays any errors to the error reporter.
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(
            errorReporter.errors as? [StateServiceError],
            [StateServiceError.noActiveAccount]
        )
    }

    /// `receive(_:)` with `sessionTimeoutActionChanged(:)` presents an alert if `logout` was selected.
    /// It then updates the state if `Yes` was tapped on the alert, confirming the user's decision.
    func test_receive_sessionTimeoutActionChanged_logout() async throws {
        XCTAssertEqual(subject.state.sessionTimeoutAction, .lock)
        subject.receive(.sessionTimeoutActionChanged(.logout))

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, Localizations.warning)
        XCTAssertEqual(alert.message, Localizations.vaultTimeoutLogOutConfirmation)
        XCTAssertEqual(alert.alertActions.count, 2)

        XCTAssertEqual(alert.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(alert.alertActions[0].style, .default)
        XCTAssertNotNil(alert.alertActions[0].handler)

        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)
        XCTAssertEqual(alert.alertActions[1].style, .cancel)
        XCTAssertNil(alert.alertActions[1].handler)

        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(subject.state.sessionTimeoutAction, .logout)
    }

    /// `receive(_:)` with `sessionTimeoutActionChanged(:)` updates the state when `lock` was selected.
    func test_receive_sessionTimeoutActionChanged_lock() async throws {
        XCTAssertEqual(subject.state.sessionTimeoutAction, .lock)
        subject.receive(.sessionTimeoutActionChanged(.logout))

        let alert = try coordinator.unwrapLastRouteAsAlert()
        try await alert.tapAction(title: Localizations.yes)
        XCTAssertEqual(subject.state.sessionTimeoutAction, .logout)

        subject.receive(.sessionTimeoutActionChanged(.lock))
        XCTAssertEqual(subject.state.sessionTimeoutAction, .lock)
    }

    /// `receive(_:)` with `sessionTimeoutActionChanged(:)` doesn't update the state if the value did not change.
    func test_receive_sessionTimeoutActionChanged_sameValue() async throws {
        subject.receive(.sessionTimeoutActionChanged(.logout))

        let alert = try coordinator.unwrapLastRouteAsAlert()
        try await alert.tapAction(title: Localizations.yes)
        XCTAssertEqual(subject.state.sessionTimeoutAction, .logout)

        subject.receive(.twoStepLoginPressed)
        let twoStepLoginAlert = try coordinator.unwrapLastRouteAsAlert()
        try await twoStepLoginAlert.tapAction(title: Localizations.cancel)

        // Should not show alert since the state's sessionTimeoutAction is already .logout
        subject.receive(.sessionTimeoutActionChanged(.logout))
        let lastShownAlert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(lastShownAlert, twoStepLoginAlert)
    }

    /// `receive(_:)` with `sessionTimeoutValueChanged(:)` updates the session timeout value in the state.
    func test_receive_sessionTimeoutValueChanged() {
        XCTAssertEqual(subject.state.sessionTimeoutValue, .immediately)
        subject.receive(.sessionTimeoutValueChanged(.never))
        XCTAssertEqual(subject.state.sessionTimeoutValue, .never)
    }

    /// `receive(_:)` with `setCustomSessionTimeoutValue(:)` updates the custom session timeout value in the state.
    func test_receive_setCustomSessionTimeoutValue() {
        XCTAssertEqual(subject.state.customSessionTimeoutValue, 60)
        subject.receive(.setCustomSessionTimeoutValue(15))
        XCTAssertEqual(subject.state.customSessionTimeoutValue, 15)
    }

    /// `receive(_:)` with `.toggleApproveLoginRequestsToggle` updates the state.
    func test_receive_toggleApproveLoginRequestsToggle() {
        subject.state.isApproveLoginRequestsToggleOn = false
        subject.receive(.toggleApproveLoginRequestsToggle(true))

        XCTAssertTrue(subject.state.isApproveLoginRequestsToggleOn)
    }

    /// `receive(_:)` with `.toggleUnlockWithPINCode` updates the state when submit has been pressed.
    func test_receive_toggleUnlockWithPINCode() async throws {
        subject.state.isUnlockWithPINCodeOn = false
        subject.receive(.toggleUnlockWithPINCode(true))

        guard case let .alert(alert) = coordinator.routes.last else {
            return XCTFail("Expected an `.alert` route, but found \(String(describing: coordinator.routes.last))")
        }

        try await alert.tapAction(title: Localizations.submit)
        XCTAssertTrue(subject.state.isUnlockWithPINCodeOn)
    }

    /// `perform(_:)` with `.loadData` updates the state.
    func test_perform_loadData_biometricsDisabled_error() async {
        struct TestError: Error, Equatable {}
        biometricsService.biometricAuthStatus = .authorized(.faceID)
        stateService.activeAccount = .fixture()
        stateService.getBiometricAuthenticationEnabledResult = .failure(TestError())
        subject.state.isUnlockWithBiometricsToggleOn = true
        await subject.perform(.loadData)

        XCTAssertFalse(subject.state.isUnlockWithBiometricsToggleOn)
    }

    /// `perform(_:)` with `.loadData` updates the state.
    func test_perform_loadData_biometricsDisabled_noPreference() async {
        stateService.activeAccount = .fixture()
        biometricsService.biometricAuthStatus = .authorized(.faceID)
        stateService.biometricsEnabled = [:]
        subject.state.isUnlockWithBiometricsToggleOn = true
        await subject.perform(.loadData)

        XCTAssertFalse(subject.state.isUnlockWithBiometricsToggleOn)
    }

    /// `perform(_:)` with `.loadData` updates the state.
    func test_perform_loadData_biometricsDisabled_success() async {
        stateService.activeAccount = .fixture()
        biometricsService.biometricAuthStatus = .authorized(.faceID)
        stateService.biometricsEnabled = [
            "1": false,
        ]
        subject.state.isUnlockWithBiometricsToggleOn = true
        await subject.perform(.loadData)

        XCTAssertFalse(subject.state.isUnlockWithBiometricsToggleOn)
    }

    /// `perform(_:)` with `.loadData` updates the state.
    func test_perform_loadData_biometricsEnabled_success() async {
        stateService.activeAccount = .fixture()
        biometricsService.biometricAuthStatus = .authorized(.faceID)
        stateService.biometricsEnabled = [
            "1": true,
        ]
        subject.state.isUnlockWithBiometricsToggleOn = true
        await subject.perform(.loadData)

        XCTAssertTrue(subject.state.isUnlockWithBiometricsToggleOn)
    }

    /// `perform(_:)` with `.toggleUnlockWithBiometrics` updates the state.
    func test_perform_toggleUnlockWithBiometrics_deleteFailure() async throws {
        struct TestError: Error, Equatable {}
        biometricsService.biometricAuthStatus = .authorized(.faceID)
        stateService.activeAccount = .fixture()
        stateService.setBiometricAuthenticationEnabledResult = .success(())
        authRepository.deleteUserBiometricAuthKeyError = TestError()
        subject.state.isUnlockWithBiometricsToggleOn = true
        await subject.perform(.toggleUnlockWithBiometrics(false))

        let error = try XCTUnwrap(errorReporter.errors.first as? TestError)
        XCTAssertEqual(error, TestError())
        XCTAssertTrue(subject.state.isUnlockWithBiometricsToggleOn)
    }

    /// `perform(_:)` with `.toggleUnlockWithBiometrics` updates the state.
    func test_perform_toggleUnlockWithBiometrics_deleteSuccess() async {
        biometricsService.biometricAuthStatus = .authorized(.faceID)
        stateService.activeAccount = .fixture()
        stateService.getBiometricAuthenticationEnabledResult = .success(())
        authRepository.deleteUserBiometricAuthKeyError = nil
        subject.state.isUnlockWithBiometricsToggleOn = true
        await subject.perform(.toggleUnlockWithBiometrics(false))

        XCTAssertFalse(subject.state.isUnlockWithBiometricsToggleOn)
    }

    /// `perform(_:)` with `.toggleUnlockWithBiometrics` updates the state.
    func test_perform_toggleUnlockWithBiometrics_setFailure() async throws {
        struct TestError: Error, Equatable {}
        biometricsService.biometricAuthStatus = .authorized(.faceID)
        stateService.activeAccount = .fixture()
        stateService.setBiometricAuthenticationEnabledResult = .failure(TestError())
        authRepository.deleteUserBiometricAuthKeyError = nil
        subject.state.isUnlockWithBiometricsToggleOn = true
        await subject.perform(.toggleUnlockWithBiometrics(false))

        let error = try XCTUnwrap(errorReporter.errors.first as? TestError)
        XCTAssertEqual(error, TestError())
        XCTAssertTrue(subject.state.isUnlockWithBiometricsToggleOn)
    }

    /// `perform(_:)` with `.toggleUnlockWithBiometrics` updates the state.
    func test_perform_toggleUnlockWithBiometrics_failure_shouldDisableBiometricsPreference() async throws {
        biometricsService.biometricAuthStatus = .denied(.faceID)
        stateService.activeAccount = .fixture()
        stateService.biometricsEnabled = [
            "1": false,
        ]
        stateService.getBiometricAuthenticationEnabledResult = .success(())
        authRepository.storeUserBiometricAuthKeyError = nil
        subject.state.isUnlockWithBiometricsToggleOn = false
        await subject.perform(.toggleUnlockWithBiometrics(true))

        XCTAssertFalse(subject.state.isUnlockWithBiometricsToggleOn)
    }

    /// `perform(_:)` with `.toggleUnlockWithBiometrics` updates the state.
    func test_perform_toggleUnlockWithBiometrics_failure_storeError() async throws {
        struct TestError: Error, Equatable {}
        biometricsService.biometricAuthStatus = .authorized(.faceID)
        stateService.activeAccount = .fixture()
        stateService.biometricsEnabled = [
            "1": false,
        ]
        stateService.getBiometricAuthenticationEnabledResult = .success(())
        authRepository.storeUserBiometricAuthKeyError = TestError()
        subject.state.isUnlockWithBiometricsToggleOn = false
        await subject.perform(.toggleUnlockWithBiometrics(true))

        let error = try XCTUnwrap(errorReporter.errors.first as? TestError)
        XCTAssertEqual(error, TestError())
        XCTAssertFalse(subject.state.isUnlockWithBiometricsToggleOn)
    }

    /// `perform(_:)` with `.toggleUnlockWithBiometrics` updates the state.
    func test_perform_toggleUnlockWithBiometrics_storeSuccess() async {
        biometricsService.biometricAuthStatus = .authorized(.faceID)
        stateService.activeAccount = .fixture()
        stateService.biometricsEnabled = [
            "1": false,
        ]
        stateService.getBiometricAuthenticationEnabledResult = .success(())
        authRepository.storeUserBiometricAuthKeyError = nil
        subject.state.isUnlockWithBiometricsToggleOn = false
        await subject.perform(.toggleUnlockWithBiometrics(true))

        XCTAssertTrue(subject.state.isUnlockWithBiometricsToggleOn)
    }

    /// `receive(_:)` with `.twoStepLoginPressed` shows the two step login alert.
    func test_receive_twoStepLoginPressed() async throws {
        subject.receive(.twoStepLoginPressed)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, Localizations.continueToWebApp)
        XCTAssertEqual(alert.message, Localizations.twoStepLoginDescriptionLong)
        XCTAssertEqual(alert.preferredStyle, .alert)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.cancel)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.yes)

        // Tapping yes navigates the user to the web app.
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertNotNil(subject.state.twoStepLoginUrl)
    }

    /// `state.twoStepLoginUrl` is initialized with the correct value.
    func test_twoStepLoginUrl() async throws {
        subject.receive(.twoStepLoginPressed)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(subject.state.twoStepLoginUrl, URL.example)
    }
}
