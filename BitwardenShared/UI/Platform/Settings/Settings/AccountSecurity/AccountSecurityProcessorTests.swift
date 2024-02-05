import XCTest

@testable import BitwardenShared

class AccountSecurityProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var authRepository: MockAuthRepository!
    var biometricsRepository: MockBiometricsRepository!
    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var errorReporter: MockErrorReporter!
    var policyService: MockPolicyService!
    var settingsRepository: MockSettingsRepository!
    var stateService: MockStateService!
    var twoStepLoginService: MockTwoStepLoginService!
    var vaultTimeoutService: MockVaultTimeoutService!
    var subject: AccountSecurityProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        authRepository = MockAuthRepository()
        biometricsRepository = MockBiometricsRepository()
        coordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
        errorReporter = MockErrorReporter()
        policyService = MockPolicyService()
        settingsRepository = MockSettingsRepository()
        stateService = MockStateService()
        twoStepLoginService = MockTwoStepLoginService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = AccountSecurityProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                biometricsRepository: biometricsRepository,
                errorReporter: errorReporter,
                policyService: policyService,
                settingsRepository: settingsRepository,
                stateService: stateService,
                twoStepLoginService: twoStepLoginService,
                vaultTimeoutService: vaultTimeoutService
            ),
            state: AccountSecurityState()
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        authRepository = nil
        biometricsRepository = nil
        coordinator = nil
        errorReporter = nil
        policyService = nil
        settingsRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` sets the state's timeout action
    /// using the data stored in the `AppSettingsStore`.
    func test_perform_appeared_sessionTimeoutAction() async throws {
        let account: Account = .fixture()
        let userId = account.profile.userId
        stateService.activeAccount = account
        stateService.timeoutAction[userId] = .logout

        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.sessionTimeoutAction, .logout)
    }

    /// `perform(_:)` with `.appeared` sets the policy related state properties when the policy is enabled.
    func test_perform_appeared_timeoutPolicyEnabled() async throws {
        policyService.fetchTimeoutPolicyValuesResult = .success((.logout, 3600))

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.isTimeoutPolicyEnabled, true)
        XCTAssertEqual(subject.state.policyTimeoutAction, .logout)
        XCTAssertEqual(subject.state.policyTimeoutValue, 3600)
        XCTAssertEqual(subject.state.availableTimeoutActions, [.logout])
        XCTAssertEqual(subject.state.policyTimeoutHours, 1)
        XCTAssertEqual(subject.state.policyTimeoutMinutes, 0)
        XCTAssertEqual(
            subject.state.availableTimeoutOptions,
            [
                .immediately,
                .oneMinute,
                .fiveMinutes,
                .fifteenMinutes,
                .thirtyMinutes,
                .oneHour,
                .custom(-100),
            ]
        )
    }

    /// `perform(_:)` with `.appeared` sets the policy related state properties when the policy is enabled,
    /// but the policy doesn't return an action.
    func test_perform_appeared_timeoutPolicyEnabled_noPolicyAction() async throws {
        policyService.fetchTimeoutPolicyValuesResult = .success((nil, 3660))

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.isTimeoutPolicyEnabled, true)
        XCTAssertEqual(subject.state.policyTimeoutValue, 3660)
        XCTAssertEqual(subject.state.availableTimeoutActions, [.lock, .logout])
        XCTAssertEqual(subject.state.policyTimeoutHours, 1)
        XCTAssertEqual(subject.state.policyTimeoutMinutes, 1)
        XCTAssertEqual(
            subject.state.availableTimeoutOptions,
            [
                .immediately,
                .oneMinute,
                .fiveMinutes,
                .fifteenMinutes,
                .thirtyMinutes,
                .oneHour,
                .custom(-100),
            ]
        )
    }

    /// `perform(_:)` with `.appeared` sets the policy related state properties when the policy is enabled.
    func test_perform_appeared_timeoutPolicyEnabled_oddTime() async throws {
        policyService.fetchTimeoutPolicyValuesResult = .success((.logout, 3660))

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.policyTimeoutHours, 1)
        XCTAssertEqual(subject.state.policyTimeoutMinutes, 1)
        XCTAssertEqual(
            subject.state.availableTimeoutOptions,
            [
                .immediately,
                .oneMinute,
                .fiveMinutes,
                .fifteenMinutes,
                .thirtyMinutes,
                .oneHour,
                .custom(-100),
            ]
        )
    }

    /// `perform(_:)` with `.loadData` loads the initial data for the view.
    func test_perform_loadData() async {
        stateService.activeAccount = .fixture()
        stateService.approveLoginRequestsByUserId["1"] = true
        authRepository.isPinUnlockAvailable = true

        await subject.perform(.loadData)

        XCTAssertTrue(subject.state.isApproveLoginRequestsToggleOn)
        XCTAssertTrue(subject.state.isUnlockWithPINCodeOn)
    }

    /// `perform(_:)` with `.loadData` records any errors.
    func test_perform_loadData_error() async {
        await subject.perform(.loadData)

        XCTAssertEqual(errorReporter.errors.last as? StateServiceError, .noActiveAccount)
    }

    /// `perform(_:)` with `.lockVault` locks the user's vault.
    func test_perform_lockVault() async {
        let account: Account = .fixture()
        stateService.activeAccount = account

        await subject.perform(.lockVault)

        XCTAssertEqual(authRepository.lockVaultUserId, nil)
        XCTAssertEqual(coordinator.events.last, .authAction(.lockVault(userId: nil)))
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

        authRepository.logoutResult = .success(())
        // Tapping yes logs the user out.
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(coordinator.events.last, .authAction(.logout(userId: nil, userInitiated: true)))
    }

    /// `.receive(_:)` with `.pendingLoginRequestsTapped` navigates to the pending requests view.
    func test_receive_pendingLoginRequestsTapped() {
        subject.receive(.pendingLoginRequestsTapped)
        XCTAssertEqual(coordinator.routes.last, .pendingLoginRequests)
    }

    /// `receive(_:)` with `sessionTimeoutActionChanged(:)` presents an alert if `logout` was selected.
    /// It then updates the state if `Yes` was tapped on the alert, confirming the user's decision.
    func test_receive_sessionTimeoutActionChanged_logout() async throws {
        stateService.activeAccount = .fixture()

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
        stateService.activeAccount = .fixture()

        subject.receive(.sessionTimeoutActionChanged(.logout))
        let alert = try coordinator.unwrapLastRouteAsAlert()
        try await alert.tapAction(title: Localizations.yes)
        XCTAssertEqual(subject.state.sessionTimeoutAction, .logout)

        subject.receive(.sessionTimeoutActionChanged(.lock))
        XCTAssertEqual(subject.state.sessionTimeoutAction, .lock)
    }

    /// `receive(_:)` with `sessionTimeoutActionChanged(:)` doesn't update the state if the value did not change.
    func test_receive_sessionTimeoutActionChanged_sameValue() async throws {
        stateService.activeAccount = .fixture()

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

    /// `receive(_:)` with `sessionTimeoutValueChanged(:)` triggers an alert when selecting never lock,
    ///  and accepting the alert sets the sessionTimeoutValue.
    func test_receive_sessionTimeoutValueChanged_neverLockAlert_accept() throws {
        XCTAssertEqual(subject.state.sessionTimeoutValue, .immediately)

        let account = Account.fixture()
        authRepository.activeAccount = account
        subject.receive(.sessionTimeoutValueChanged(.never))
        waitFor(!coordinator.routes.isEmpty)

        let neverLockAlert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(neverLockAlert, Alert.neverLockAlert {})
        var didAccept = false
        let accept = Task {
            try await neverLockAlert.tapAction(title: Localizations.yes)
            didAccept = true
        }
        waitFor(didAccept)
        accept.cancel()

        XCTAssertEqual(subject.state.sessionTimeoutValue, .never)
    }

    /// `receive(_:)` with `sessionTimeoutValueChanged(:)` triggers an alert when selecting never lock,
    ///  and declining the alert does not set the sessionTimeoutValue.
    func test_receive_sessionTimeoutValueChanged_neverLockAlert_cancel() throws {
        XCTAssertEqual(subject.state.sessionTimeoutValue, .immediately)

        let account = Account.fixture()
        stateService.activeAccount = account
        subject.receive(.sessionTimeoutValueChanged(.never))
        waitFor(!coordinator.routes.isEmpty)

        let neverLockAlert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(neverLockAlert, Alert.neverLockAlert {})
        let dismiss = Task {
            try await neverLockAlert.tapAction(title: Localizations.cancel)
            coordinator.routes = []
        }
        waitFor(coordinator.routes.isEmpty)
        dismiss.cancel()
        XCTAssertEqual(subject.state.sessionTimeoutValue, .immediately)
    }

    /// `receive(_:)` with `sessionTimeoutValueChanged(:)` triggers an alert when selecting never lock,
    ///  and any error is surfaced correctly.
    func test_receive_sessionTimeoutValueChanged_neverLockAlert_error() throws {
        XCTAssertEqual(subject.state.sessionTimeoutValue, .immediately)

        let account = Account.fixture()
        authRepository.activeAccount = account
        authRepository.setVaultTimeoutError = BitwardenTestError.example
        subject.receive(.sessionTimeoutValueChanged(.never))
        waitFor(!coordinator.routes.isEmpty)

        let neverLockAlert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(neverLockAlert, Alert.neverLockAlert {})
        let accept = Task {
            try await neverLockAlert.tapAction(title: Localizations.yes)
        }
        waitFor(!errorReporter.errors.isEmpty)
        accept.cancel()

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, BitwardenTestError.example)
        XCTAssertEqual(subject.state.sessionTimeoutValue, .immediately)
    }

    /// `receive(_:)` with `sessionTimeoutValueChanged(:)` updates the session timeout value in the state.
    func test_receive_sessionTimeoutValueChanged_noAlert() {
        XCTAssertEqual(subject.state.sessionTimeoutValue, .immediately)

        let account = Account.fixture()
        authRepository.activeAccount = account
        subject.receive(.sessionTimeoutValueChanged(.fiveMinutes))
        waitFor(subject.state.sessionTimeoutValue == .fiveMinutes)
    }

    /// `receive(_:)` with `sessionTimeoutValueChanged(:)` shows an alert when the user
    /// enters a value that exceeds the policy limit. It also sets the user's timeout to the policy limit.
    func test_receive_sessionTimeoutValueChanged_policy_exceedsLimit() throws {
        let account = Account.fixture()
        authRepository.activeAccount = account
        subject.state.isTimeoutPolicyEnabled = true
        subject.state.policyTimeoutValue = 60

        subject.receive(.sessionTimeoutValueChanged(.fourHours))

        waitFor(authRepository.vaultTimeout["1"] == .oneMinute)
    }

    /// `receive(_:)` with `sessionTimeoutValueChanged(:)` shows an alert when the user
    /// enters a value that exceeds the policy limit. It surfaces any error when setting the policy value.
    func test_receive_sessionTimeoutValueChanged_policy_exceedsLimit_error() throws {
        let account = Account.fixture()
        authRepository.activeAccount = account
        authRepository.setVaultTimeoutError = BitwardenTestError.example
        subject.state.isTimeoutPolicyEnabled = true
        subject.state.policyTimeoutValue = 60

        subject.receive(.sessionTimeoutValueChanged(.fourHours))

        waitFor(errorReporter.errors.last as? BitwardenTestError == BitwardenTestError.example)
    }

    /// `receive(_:)` with `setCustomSessionTimeoutValue(_:)` updates the custom session timeout value in the state.
    func test_receive_setCustomSessionTimeoutValue() {
        XCTAssertEqual(subject.state.customTimeoutValue, 60)

        let account = Account.fixture()
        authRepository.activeAccount = account

        subject.receive(.customTimeoutValueChanged(120))
        waitFor(subject.state.customTimeoutValue == 120)
    }

    /// `receive(_:)` with `.toggleApproveLoginRequestsToggle` shows a confirmation alert and updates the state.
    func test_receive_toggleApproveLoginRequestsToggle() async throws {
        stateService.activeAccount = .fixture()
        subject.state.isApproveLoginRequestsToggleOn = false

        subject.receive(.toggleApproveLoginRequestsToggle(true))

        // Confirm enabling the setting on the alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.last)
        await confirmAction.handler?(confirmAction, [])

        waitFor(subject.state.isApproveLoginRequestsToggleOn)
        XCTAssertEqual(stateService.approveLoginRequestsByUserId["1"], true)
    }

    /// `receive(_:)` with `.toggleApproveLoginRequestsToggle` records any errors.
    func test_receive_toggleApproveLoginRequestsToggle_error() async throws {
        subject.state.isApproveLoginRequestsToggleOn = false

        subject.receive(.toggleApproveLoginRequestsToggle(true))

        // Confirm enabling the setting on the alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.last)
        await confirmAction.handler?(confirmAction, [])

        waitFor(!errorReporter.errors.isEmpty)
        XCTAssertEqual(errorReporter.errors.last as? StateServiceError, .noActiveAccount)
    }

    /// `receive(_:)` with `.toggleApproveLoginRequestsToggle` updates the state.
    func test_receive_toggleApproveLoginRequestsToggle_toggleOff() {
        stateService.activeAccount = .fixture()
        subject.state.isApproveLoginRequestsToggleOn = true

        let task = Task {
            subject.receive(.toggleApproveLoginRequestsToggle(false))
        }

        waitFor(!subject.state.isApproveLoginRequestsToggleOn)
        task.cancel()
        XCTAssertEqual(stateService.approveLoginRequestsByUserId["1"], false)
    }

    /// `receive(_:)` with `.toggleUnlockWithPINCode` updates the state when submit has been pressed.
    func test_receive_toggleUnlockWithPINCode_toggleOff() {
        subject.state.isUnlockWithPINCodeOn = true

        let task = Task {
            subject.receive(.toggleUnlockWithPINCode(false))
        }

        waitFor(subject.state.isUnlockWithPINCodeOn == false)
        task.cancel()

        XCTAssertFalse(subject.state.isUnlockWithPINCodeOn)
        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `receive(_:)` with `.toggleUnlockWithPINCode` displays an alert and updates the state when submit has been
    /// pressed.
    func test_receive_toggleUnlockWithPINCode_toggleOn() async throws {
        subject.state.isUnlockWithPINCodeOn = false
        subject.receive(.toggleUnlockWithPINCode(true))

        guard case let .alert(alert) = coordinator.routes.last else {
            return XCTFail("Expected an `.alert` route, but found \(String(describing: coordinator.routes.last))")
        }

        try await alert.tapAction(title: Localizations.submit)

        guard case let .alert(alert) = coordinator.routes.last else {
            return XCTFail("Expected an `.alert` route, but found \(String(describing: coordinator.routes.last))")
        }

        try await alert.tapAction(title: Localizations.yes)
        XCTAssertTrue(subject.state.isUnlockWithPINCodeOn)
    }

    /// `receive(_:)` with `.toggleUnlockWithPINCode` turns the toggle off and clears the user's pins.
    func test_receive_toggleUnlockWithPINCode_off() {
        let account: Account = .fixture()
        stateService.activeAccount = account
        stateService.pinProtectedUserKeyValue[account.profile.userId] = "123"

        subject.state.isUnlockWithPINCodeOn = true
        let task = Task {
            subject.receive(.toggleUnlockWithPINCode(false))
        }
        waitFor(!subject.state.isUnlockWithPINCodeOn)
        task.cancel()
        XCTAssertTrue(authRepository.clearPinsCalled)
    }

    /// `perform(_:)` with `.loadData` updates the state.
    func test_perform_loadData_biometricsValue() async {
        let biometricUnlockStatus = BiometricsUnlockStatus.available(.faceID, enabled: true, hasValidIntegrity: true)
        biometricsRepository.biometricUnlockStatus = .success(
            biometricUnlockStatus
        )
        subject.state.biometricUnlockStatus = .notAvailable
        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricUnlockStatus, biometricUnlockStatus)
    }

    /// `perform(_:)` with `.loadData` updates the state.
    func test_perform_loadData_biometricsValue_error() async {
        struct TestError: Error {}
        biometricsRepository.biometricUnlockStatus = .failure(TestError())
        subject.state.biometricUnlockStatus = .notAvailable
        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricUnlockStatus, .notAvailable)
    }

    /// `perform(_:)` with `.toggleUnlockWithBiometrics` updates the state.
    func test_perform_toggleUnlockWithBiometrics_authRepositoryFailure() async throws {
        struct TestError: Error, Equatable {}
        let biometricUnlockStatus = BiometricsUnlockStatus.available(.faceID, enabled: true, hasValidIntegrity: true)
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.touchID, enabled: false, hasValidIntegrity: false)
        )

        authRepository.allowBiometricUnlockResult = .failure(TestError())
        subject.state.biometricUnlockStatus = biometricUnlockStatus
        await subject.perform(.toggleUnlockWithBiometrics(false))

        let error = try XCTUnwrap(errorReporter.errors.first as? TestError)
        XCTAssertEqual(error, TestError())
        XCTAssertEqual(subject.state.biometricUnlockStatus, biometricUnlockStatus)
    }

    /// `perform(_:)` with `.toggleUnlockWithBiometrics` updates the state.
    func test_perform_toggleUnlockWithBiometrics_biometricsRepositoryFailure() async throws {
        struct TestError: Error, Equatable {}
        let biometricUnlockStatus = BiometricsUnlockStatus.available(.faceID, enabled: true, hasValidIntegrity: true)
        biometricsRepository.biometricUnlockStatus = .failure(TestError())

        authRepository.allowBiometricUnlockResult = .success(())
        subject.state.biometricUnlockStatus = biometricUnlockStatus
        await subject.perform(.toggleUnlockWithBiometrics(false))

        let error = try XCTUnwrap(errorReporter.errors.first as? TestError)
        XCTAssertEqual(error, TestError())
        XCTAssertEqual(subject.state.biometricUnlockStatus, biometricUnlockStatus)
    }

    /// `perform(_:)` with `.toggleUnlockWithBiometrics` configures biometric integrity state if needed.
    func test_perform_toggleUnlockWithBiometrics_invalidBiometryState() async {
        let biometricUnlockStatus = BiometricsUnlockStatus.available(.faceID, enabled: true, hasValidIntegrity: false)
        biometricsRepository.biometricUnlockStatus = .success(
            biometricUnlockStatus
        )
        authRepository.allowBiometricUnlockResult = .success(())
        subject.state.biometricUnlockStatus = .available(.faceID, enabled: false, hasValidIntegrity: false)
        await subject.perform(.toggleUnlockWithBiometrics(false))

        XCTAssertTrue(biometricsRepository.didConfigureBiometricIntegrity)
    }

    /// `perform(_:)` with `.toggleUnlockWithBiometrics` updates the state.
    func test_perform_toggleUnlockWithBiometrics_success() async {
        let biometricUnlockStatus = BiometricsUnlockStatus.available(.faceID, enabled: false, hasValidIntegrity: true)
        biometricsRepository.biometricUnlockStatus = .success(
            biometricUnlockStatus
        )
        authRepository.allowBiometricUnlockResult = .success(())
        subject.state.biometricUnlockStatus = .available(.faceID, enabled: true, hasValidIntegrity: true)
        await subject.perform(.toggleUnlockWithBiometrics(false))

        XCTAssertEqual(
            subject.state.biometricUnlockStatus,
            biometricUnlockStatus
        )
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
} // swiftlint:disable:this file_length
