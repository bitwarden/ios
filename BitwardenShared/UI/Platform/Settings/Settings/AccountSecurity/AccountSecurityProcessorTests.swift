import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

@testable import BitwardenShared

class AccountSecurityProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var authRepository: MockAuthRepository!
    var biometricsRepository: MockBiometricsRepository!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var errorReporter: MockErrorReporter!
    var policyService: MockPolicyService!
    var settingsRepository: MockSettingsRepository!
    var stateService: MockStateService!
    var twoStepLoginService: MockTwoStepLoginService!
    var vaultTimeoutService: MockVaultTimeoutService!
    var subject: AccountSecurityProcessor!
    var vaultUnlockSetupHelper: MockVaultUnlockSetupHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        authRepository = MockAuthRepository()
        biometricsRepository = MockBiometricsRepository()
        configService = MockConfigService()
        coordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
        errorReporter = MockErrorReporter()
        policyService = MockPolicyService()
        settingsRepository = MockSettingsRepository()
        stateService = MockStateService()
        twoStepLoginService = MockTwoStepLoginService()
        vaultTimeoutService = MockVaultTimeoutService()
        vaultUnlockSetupHelper = MockVaultUnlockSetupHelper()

        subject = AccountSecurityProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                biometricsRepository: biometricsRepository,
                configService: configService,
                errorReporter: errorReporter,
                policyService: policyService,
                settingsRepository: settingsRepository,
                stateService: stateService,
                twoStepLoginService: twoStepLoginService,
                vaultTimeoutService: vaultTimeoutService
            ),
            state: AccountSecurityState(),
            vaultUnlockSetupHelper: vaultUnlockSetupHelper
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        authRepository = nil
        biometricsRepository = nil
        configService = nil
        coordinator = nil
        errorReporter = nil
        policyService = nil
        settingsRepository = nil
        subject = nil
        vaultUnlockSetupHelper = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` sets the state's timeout action
    /// using the data stored in the `AppSettingsStore`.
    @MainActor
    func test_perform_appeared_sessionTimeoutAction() async throws {
        let account: Account = .fixture()
        let userId = account.profile.userId
        stateService.activeAccount = account
        authRepository.activeAccount = account
        authRepository.sessionTimeoutAction[userId] = .logout

        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.sessionTimeoutAction, .logout)
        XCTAssertNil(subject.state.policyTimeoutMessage)
    }

    /// `perform(_:)` with `.appeared` sets the policy related state properties when the policy is enabled.
    @MainActor
    func test_perform_appeared_timeoutPolicyEnabled() async throws {
        policyService.fetchTimeoutPolicyValuesResult = .success((.logout, 60))

        await subject.perform(.appeared)

        XCTAssertTrue(subject.state.isTimeoutPolicyEnabled)
        XCTAssertTrue(subject.state.isTimeoutActionPolicyEnabled)
        XCTAssertTrue(subject.state.isSessionTimeoutActionDisabled)
        XCTAssertEqual(subject.state.policyTimeoutValue, 60)
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
        XCTAssertEqual(
            subject.state.policyTimeoutMessage,
            Localizations.vaultTimeoutPolicyWithActionInEffect(1, 0, Localizations.logOut)
        )
    }

    /// `perform(_:)` with `.appeared` sets the policy related state properties when the policy is enabled,
    /// but the policy doesn't return an action.
    @MainActor
    func test_perform_appeared_timeoutPolicyEnabled_noPolicyAction() async throws {
        policyService.fetchTimeoutPolicyValuesResult = .success((nil, 61))

        await subject.perform(.appeared)

        XCTAssertFalse(subject.state.isTimeoutActionPolicyEnabled)
        XCTAssertTrue(subject.state.isTimeoutPolicyEnabled)
        XCTAssertFalse(subject.state.isSessionTimeoutActionDisabled)
        XCTAssertEqual(subject.state.policyTimeoutValue, 61)
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
        XCTAssertEqual(subject.state.policyTimeoutMessage, Localizations.vaultTimeoutPolicyInEffect(1, 1))
    }

    /// `perform(_:)` with `.appeared` sets the policy related state properties when the policy is enabled.
    @MainActor
    func test_perform_appeared_timeoutPolicyEnabled_oddTime() async throws {
        policyService.fetchTimeoutPolicyValuesResult = .success((.lock, 61))

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
        XCTAssertEqual(
            subject.state.policyTimeoutMessage,
            Localizations.vaultTimeoutPolicyWithActionInEffect(1, 1, Localizations.lock)
        )
    }

    /// `perform(_:)` with `.dismissSetUpUnlockActionCard` sets the user's vault unlock setup
    /// progress to complete.
    @MainActor
    func test_perform_dismissSetUpUnlockActionCard() async {
        stateService.activeAccount = .fixture()
        stateService.accountSetupVaultUnlock["1"] = .setUpLater

        await subject.perform(.dismissSetUpUnlockActionCard)

        XCTAssertEqual(stateService.accountSetupVaultUnlock["1"], .complete)
    }

    /// `perform(_:)` with `.dismissSetUpUnlockActionCard` logs an error and shows an alert if an
    /// error occurs.
    @MainActor
    func test_perform_dismissSetUpUnlockActionCard_error() async {
        await subject.perform(.dismissSetUpUnlockActionCard)

        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `perform(_:)` with `.loadData` loads the initial data for the view.
    @MainActor
    func test_perform_loadData() async {
        stateService.activeAccount = .fixture()
        authRepository.isPinUnlockAvailableResult = .success(true)

        await subject.perform(.loadData)

        XCTAssertTrue(subject.state.isUnlockWithPINCodeOn)
        XCTAssertFalse(subject.state.removeUnlockWithPinPolicyEnabled)
    }

    /// `perform(_:)` with `.loadData` updates the state.
    @MainActor
    func test_perform_loadData_biometricsValue() async {
        let biometricUnlockStatus = BiometricsUnlockStatus.available(.faceID, enabled: true)
        biometricsRepository.biometricUnlockStatus = .success(
            biometricUnlockStatus
        )
        subject.state.biometricUnlockStatus = .notAvailable
        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricUnlockStatus, biometricUnlockStatus)
    }

    /// `perform(_:)` with `.loadData` updates the state.
    @MainActor
    func test_perform_loadData_biometricsValue_error() async {
        struct TestError: Error {}
        biometricsRepository.biometricUnlockStatus = .failure(TestError())
        subject.state.biometricUnlockStatus = .notAvailable
        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.biometricUnlockStatus, .notAvailable)
    }

    /// `perform(_:)` with `.loadData` records any errors.
    func test_perform_loadData_error() async {
        authRepository.isPinUnlockAvailableResult = .failure(StateServiceError.noActiveAccount)

        await subject.perform(.loadData)

        XCTAssertEqual(errorReporter.errors.last as? StateServiceError, .noActiveAccount)
    }

    /// `perform(_:)` with `.loadData` updates the state. The `isAuthenticatorSyncEnabled`
    /// should be set to the user's current `syncToAuthenticator` setting.
    @MainActor
    func test_perform_loadData_isAuthenticatorSyncEnabled() async {
        stateService.activeAccount = .fixture()

        stateService.syncToAuthenticatorByUserId[Account.fixture().profile.userId] = false
        await subject.perform(.loadData)
        XCTAssertFalse(subject.state.isAuthenticatorSyncEnabled)

        stateService.syncToAuthenticatorByUserId[Account.fixture().profile.userId] = true
        await subject.perform(.loadData)
        XCTAssertTrue(subject.state.isAuthenticatorSyncEnabled)
    }

    /// `perform(_:)` with `.loadData` completes the vault unlock setup progress if biometrics are enabled.
    @MainActor
    func test_perform_loadData_vaultUnlockSetupProgress_biometrics() async {
        stateService.activeAccount = .fixture()
        stateService.accountSetupVaultUnlock["1"] = .setUpLater

        biometricsRepository.biometricUnlockStatus = .success(.available(.faceID, enabled: false))
        await subject.perform(.loadData)
        XCTAssertEqual(stateService.accountSetupVaultUnlock["1"], .setUpLater)

        biometricsRepository.biometricUnlockStatus = .success(.available(.faceID, enabled: true))
        await subject.perform(.loadData)
        XCTAssertEqual(stateService.accountSetupVaultUnlock["1"], .complete)
    }

    /// `perform(_:)` with `.loadData` completes the vault unlock setup progress if pin unlock is enabled.
    @MainActor
    func test_perform_loadData_vaultUnlockSetupProgress_pin() async {
        stateService.activeAccount = .fixture()
        stateService.accountSetupVaultUnlock["1"] = .setUpLater

        authRepository.isPinUnlockAvailableResult = .success(false)
        await subject.perform(.loadData)
        XCTAssertEqual(stateService.accountSetupVaultUnlock["1"], .setUpLater)

        authRepository.isPinUnlockAvailableResult = .success(true)
        await subject.perform(.loadData)
        XCTAssertEqual(stateService.accountSetupVaultUnlock["1"], .complete)
    }

    /// `perform(_:)` with `.loadData` loads the initial data for the view with remove unlock pin policy enabled.
    @MainActor
    func test_perform_loadData_removeUnlockPinPolicy() async {
        stateService.activeAccount = .fixture()
        authRepository.isPinUnlockAvailableResult = .success(true)
        policyService.policyAppliesToUserResult[.removeUnlockWithPin] = true

        await subject.perform(.loadData)

        XCTAssertTrue(subject.state.isUnlockWithPINCodeOn)
        XCTAssertTrue(subject.state.removeUnlockWithPinPolicyEnabled)
    }

    /// `perform(_:)` with `.lockVault` locks the user's vault.
    @MainActor
    func test_perform_lockVault() async {
        let account: Account = .fixture()
        stateService.activeAccount = account

        await subject.perform(.lockVault)

        XCTAssertEqual(authRepository.lockVaultUserId, nil)
        XCTAssertEqual(coordinator.events.last, .authAction(.lockVault(userId: nil, isManuallyLocking: true)))
    }

    /// `perform(_:)` with `.streamSettingsBadge` updates the state's badge state whenever it changes.
    @MainActor
    func test_perform_streamSettingsBadge() {
        stateService.activeAccount = .fixture()

        let task = Task {
            await subject.perform(.streamSettingsBadge)
        }
        defer { task.cancel() }

        let badgeState = SettingsBadgeState.fixture(vaultUnlockSetupProgress: .setUpLater)
        stateService.settingsBadgeSubject.send(badgeState)
        waitFor { subject.state.badgeState == badgeState }

        XCTAssertEqual(subject.state.badgeState, badgeState)
    }

    /// `perform(_:)` with `.streamSettingsBadge` logs an error if streaming the settings badge state fails.
    @MainActor
    func test_perform_streamSettingsBadge_error() async {
        await subject.perform(.streamSettingsBadge)

        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `perform(_:)` with `.accountFingerprintPhrasePressed` navigates to the web app
    /// and clears the fingerprint phrase URL.
    @MainActor
    func test_perform_showAccountFingerprintPhraseAlert() async throws {
        stateService.activeAccount = .fixture()
        await subject.perform(.accountFingerprintPhrasePressed)

        let fingerprint = try authRepository.fingerprintPhraseResult.get()
        let alert = try XCTUnwrap(coordinator.alertShown.last)
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
    @MainActor
    func test_perform_showAccountFingerprintPhraseAlert_error() async throws {
        struct FingerprintPhraseError: Error {}

        authRepository.fingerprintPhraseResult = .failure(FingerprintPhraseError())
        await subject.perform(.accountFingerprintPhrasePressed)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred
            )
        )
    }

    /// `perform(_:)` with `.toggleSyncWithAuthenticator` disables authenticator sync and updates the state.
    @MainActor
    func test_perform_toggleSyncWithAuthenticator_disable() async throws {
        stateService.activeAccount = .fixture()
        subject.state.isAuthenticatorSyncEnabled = true

        await subject.perform(.toggleSyncWithAuthenticator(false))
        waitFor { !subject.state.isAuthenticatorSyncEnabled }

        let syncEnabled = try await stateService.getSyncToAuthenticator()
        XCTAssertFalse(syncEnabled)
    }

    /// `perform(_:)` with `.toggleSyncWithAuthenticator` enables authenticator sync,
    /// updates the state, and attempts a sync.
    @MainActor
    func test_perform_toggleSyncWithAuthenticator_enable() async throws {
        stateService.activeAccount = .fixture()
        subject.state.isAuthenticatorSyncEnabled = false

        await subject.perform(.toggleSyncWithAuthenticator(true))
        waitFor { subject.state.isAuthenticatorSyncEnabled }

        let syncEnabled = try await stateService.getSyncToAuthenticator()
        XCTAssertTrue(syncEnabled)

        waitFor { settingsRepository.fetchSyncCalled }
        XCTAssertEqual(settingsRepository.fetchSyncForceSync, false)
    }

    /// `perform(_:)` with `.toggleSyncWithAuthenticator` correctly handles and logs errors.
    @MainActor
    func test_perform_toggleSyncWithAuthenticator_error() async throws {
        subject.state.isAuthenticatorSyncEnabled = false
        stateService.syncToAuthenticatorResult = .failure(BitwardenTestError.example)
        await subject.perform(.toggleSyncWithAuthenticator(true))
        waitFor { !errorReporter.errors.isEmpty }
        XCTAssertFalse(subject.state.isAuthenticatorSyncEnabled)
    }

    /// `perform(_:)` with `.toggleUnlockWithBiometrics` disables biometrics unlock and updates the state.
    @MainActor
    func test_perform_toggleUnlockWithBiometrics_disable() async {
        stateService.activeAccount = .fixture()
        subject.state.biometricUnlockStatus = .available(.faceID, enabled: true)
        vaultUnlockSetupHelper.setBiometricUnlockStatus = .available(
            .faceID,
            enabled: false
        )

        await subject.perform(.toggleUnlockWithBiometrics(false))
        waitFor { !subject.state.biometricUnlockStatus.isEnabled }

        XCTAssertTrue(vaultUnlockSetupHelper.setBiometricUnlockCalled)
        XCTAssertTrue(stateService.accountSetupVaultUnlock.isEmpty)
        XCTAssertFalse(subject.state.biometricUnlockStatus.isEnabled)
    }

    /// `perform(_:)` with `.toggleUnlockWithBiometrics` disables biometrics unlock and updates the
    /// state, refreshing the user's timeout action in case the user doesn't have a password and no
    /// other unlock method.
    @MainActor
    func test_perform_toggleUnlockWithBiometrics_disable_noPassword() async {
        authRepository.activeAccount = .fixtureWithTdeNoPassword()
        authRepository.sessionTimeoutAction["1"] = .logout
        stateService.activeAccount = .fixture()
        subject.state.biometricUnlockStatus = .available(.faceID, enabled: true)
        subject.state.sessionTimeoutAction = .lock
        vaultUnlockSetupHelper.setBiometricUnlockStatus = .available(
            .faceID,
            enabled: false
        )

        await subject.perform(.toggleUnlockWithBiometrics(false))
        waitFor { !subject.state.biometricUnlockStatus.isEnabled }

        XCTAssertTrue(vaultUnlockSetupHelper.setBiometricUnlockCalled)
        XCTAssertTrue(stateService.accountSetupVaultUnlock.isEmpty)
        XCTAssertFalse(subject.state.biometricUnlockStatus.isEnabled)
        XCTAssertEqual(subject.state.sessionTimeoutAction, .logout)
    }

    /// `perform(_:)` with `.toggleUnlockWithBiometrics` enables biometrics unlock and updates the state.
    @MainActor
    func test_perform_toggleUnlockWithBiometrics_enable() async {
        stateService.activeAccount = .fixture()
        stateService.accountSetupVaultUnlock["1"] = .setUpLater
        subject.state.biometricUnlockStatus = .available(.faceID, enabled: true)
        vaultUnlockSetupHelper.setBiometricUnlockStatus = .available(
            .faceID,
            enabled: true
        )

        await subject.perform(.toggleUnlockWithBiometrics(true))
        waitFor { subject.state.biometricUnlockStatus.isEnabled }

        XCTAssertTrue(vaultUnlockSetupHelper.setBiometricUnlockCalled)
        XCTAssertEqual(stateService.accountSetupVaultUnlock, ["1": .complete])
        XCTAssertTrue(subject.state.biometricUnlockStatus.isEnabled)
    }

    /// `perform(_:)` with `.toggleUnlockWithPINCode` disables pin unlock and updates the state.
    @MainActor
    func test_perform_toggleUnlockWithPINCode_disable() async {
        stateService.activeAccount = .fixture()
        vaultUnlockSetupHelper.setPinUnlockResult = true

        await subject.perform(.toggleUnlockWithPINCode(false))

        XCTAssertTrue(vaultUnlockSetupHelper.setPinUnlockCalled)
        XCTAssertTrue(stateService.accountSetupVaultUnlock.isEmpty)
        XCTAssertTrue(subject.state.isUnlockWithPINCodeOn)
    }

    /// `perform(_:)` with `.toggleUnlockWithPINCode` disables pin unlock and updates the state,
    /// refreshing the user's timeout action in case the user doesn't have a password and no other
    /// unlock method.
    @MainActor
    func test_perform_toggleUnlockWithPINCode_disable_noPassword() async {
        authRepository.activeAccount = .fixtureWithTdeNoPassword()
        authRepository.sessionTimeoutAction["1"] = .logout
        stateService.activeAccount = .fixture()
        subject.state.sessionTimeoutAction = .lock
        vaultUnlockSetupHelper.setPinUnlockResult = true

        await subject.perform(.toggleUnlockWithPINCode(false))

        XCTAssertTrue(vaultUnlockSetupHelper.setPinUnlockCalled)
        XCTAssertTrue(stateService.accountSetupVaultUnlock.isEmpty)
        XCTAssertTrue(subject.state.isUnlockWithPINCodeOn)
        XCTAssertEqual(subject.state.sessionTimeoutAction, .logout)
    }

    /// `perform(_:)` with `.toggleUnlockWithPINCode` enables pin unlock and updates the state.
    @MainActor
    func test_receive_toggleUnlockWithPINCode_enable() async {
        stateService.activeAccount = .fixture()
        stateService.accountSetupVaultUnlock["1"] = .setUpLater
        subject.state.isUnlockWithPINCodeOn = true
        vaultUnlockSetupHelper.setPinUnlockResult = false

        await subject.perform(.toggleUnlockWithPINCode(true))
        waitFor { !subject.state.isUnlockWithPINCodeOn }

        XCTAssertTrue(vaultUnlockSetupHelper.setPinUnlockCalled)
        XCTAssertEqual(stateService.accountSetupVaultUnlock, ["1": .complete])
        XCTAssertFalse(subject.state.isUnlockWithPINCodeOn)
    }

    /// `perform(_:)` with `.toggleUnlockWithPINCode` doesn't update the user's vault unlock setup
    /// progress if they don't yet have any progress.
    @MainActor
    func test_receive_toggleUnlockWithPINCode_enable_noVaultUnlockSetupProgress() async {
        stateService.activeAccount = .fixture()
        subject.state.isUnlockWithPINCodeOn = true
        vaultUnlockSetupHelper.setPinUnlockResult = false

        await subject.perform(.toggleUnlockWithPINCode(true))
        waitFor { !subject.state.isUnlockWithPINCodeOn }

        XCTAssertTrue(vaultUnlockSetupHelper.setPinUnlockCalled)
        XCTAssertTrue(stateService.accountSetupVaultUnlock.isEmpty)
        XCTAssertFalse(subject.state.isUnlockWithPINCodeOn)
    }

    /// `perform(_:)` with `.toggleUnlockWithPINCode` logs an error if one occurs updating the
    /// user's vault unlock setup progress.
    @MainActor
    func test_receive_toggleUnlockWithPINCode_enable_vaultUnlockSetupError() async {
        stateService.accountSetupVaultUnlock["1"] = .setUpLater
        subject.state.isUnlockWithPINCodeOn = true
        vaultUnlockSetupHelper.setPinUnlockResult = false

        await subject.perform(.toggleUnlockWithPINCode(true))
        waitFor { !subject.state.isUnlockWithPINCodeOn }

        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
        XCTAssertTrue(vaultUnlockSetupHelper.setPinUnlockCalled)
        XCTAssertEqual(stateService.accountSetupVaultUnlock, ["1": .setUpLater])
        XCTAssertFalse(subject.state.isUnlockWithPINCodeOn)
    }

    /// `receive(_:)` with `.twoStepLoginPressed` clears the two step login URL.
    @MainActor
    func test_receive_clearTwoStepLoginUrl() async throws {
        subject.receive(.twoStepLoginPressed)

        let alert = try XCTUnwrap(coordinator.alertShown.last)

        // Tapping yes navigates the user to the web app.
        try await alert.tapAction(title: Localizations.yes)
        XCTAssertNotNil(subject.state.twoStepLoginUrl)

        subject.receive(.clearTwoStepLoginUrl)
        XCTAssertNil(subject.state.twoStepLoginUrl)
    }

    /// `receive(_:)` with `customTimeoutValueSecondsChanged(_:)` updates the custom session timeout value in the state.
    @MainActor
    func test_receive_customTimeoutValueSecondsChanged() {
        XCTAssertEqual(subject.state.customTimeoutValueSeconds, 60)

        let account = Account.fixture()
        authRepository.activeAccount = account

        subject.receive(.customTimeoutValueSecondsChanged(120))
        waitFor(subject.state.customTimeoutValueSeconds == 120)
    }

    /// `receive(_:)` with `.deleteAccountPressed` shows the `DeleteAccountView`.
    @MainActor
    func test_receive_deleteAccountPressed() throws {
        subject.receive(.deleteAccountPressed)

        XCTAssertEqual(coordinator.routes.last, .deleteAccount)
    }

    /// `receive(_:)` with `.logout` presents a logout confirmation alert.
    @MainActor
    func test_receive_logout() async throws {
        subject.receive(.logout)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
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
    @MainActor
    func test_receive_pendingLoginRequestsTapped() {
        subject.receive(.pendingLoginRequestsTapped)
        XCTAssertEqual(coordinator.routes.last, .pendingLoginRequests)
    }

    /// `receive(_:)` with `sessionTimeoutActionChanged(:)` presents an alert if `logout` was selected.
    /// It then updates the state if `Yes` was tapped on the alert, confirming the user's decision.
    @MainActor
    func test_receive_sessionTimeoutActionChanged_logout() async throws {
        stateService.activeAccount = .fixture()

        subject.receive(.sessionTimeoutActionChanged(.logout))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
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
    @MainActor
    func test_receive_sessionTimeoutActionChanged_lock() async throws {
        stateService.activeAccount = .fixture()

        subject.receive(.sessionTimeoutActionChanged(.logout))
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.yes)
        XCTAssertEqual(subject.state.sessionTimeoutAction, .logout)

        subject.receive(.sessionTimeoutActionChanged(.lock))
        XCTAssertEqual(subject.state.sessionTimeoutAction, .lock)
    }

    /// `receive(_:)` with `sessionTimeoutActionChanged(:)` doesn't update the state if the value did not change.
    @MainActor
    func test_receive_sessionTimeoutActionChanged_sameValue() async throws {
        stateService.activeAccount = .fixture()

        subject.receive(.sessionTimeoutActionChanged(.logout))
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.yes)
        XCTAssertEqual(subject.state.sessionTimeoutAction, .logout)

        subject.receive(.twoStepLoginPressed)
        let twoStepLoginAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await twoStepLoginAlert.tapAction(title: Localizations.cancel)

        // Should not show alert since the state's sessionTimeoutAction is already .logout
        subject.receive(.sessionTimeoutActionChanged(.logout))
        let lastShownAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(lastShownAlert, twoStepLoginAlert)
    }

    /// `receive(_:)` with `sessionTimeoutValueChanged(:)` triggers an alert when selecting never lock,
    ///  and accepting the alert sets the sessionTimeoutValue.
    @MainActor
    func test_receive_sessionTimeoutValueChanged_neverLockAlert_accept() throws {
        XCTAssertEqual(subject.state.sessionTimeoutValue, .immediately)

        let account = Account.fixture()
        authRepository.activeAccount = account
        subject.receive(.sessionTimeoutValueChanged(.never))
        waitFor(!coordinator.alertShown.isEmpty)

        let neverLockAlert = try XCTUnwrap(coordinator.alertShown.last)
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
    @MainActor
    func test_receive_sessionTimeoutValueChanged_neverLockAlert_cancel() throws {
        XCTAssertEqual(subject.state.sessionTimeoutValue, .immediately)

        let account = Account.fixture()
        stateService.activeAccount = account
        subject.receive(.sessionTimeoutValueChanged(.never))
        waitFor(!coordinator.alertShown.isEmpty)

        let neverLockAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(neverLockAlert, Alert.neverLockAlert {})
        let dismiss = Task {
            try await neverLockAlert.tapAction(title: Localizations.cancel)
            coordinator.alertShown = []
        }
        waitFor(coordinator.alertShown.isEmpty)
        dismiss.cancel()
        XCTAssertEqual(subject.state.sessionTimeoutValue, .immediately)
    }

    /// `receive(_:)` with `sessionTimeoutValueChanged(:)` triggers an alert when selecting never lock,
    ///  and any error is surfaced correctly.
    @MainActor
    func test_receive_sessionTimeoutValueChanged_neverLockAlert_error() throws {
        XCTAssertEqual(subject.state.sessionTimeoutValue, .immediately)

        let account = Account.fixture()
        authRepository.activeAccount = account
        authRepository.setVaultTimeoutError = BitwardenTestError.example
        subject.receive(.sessionTimeoutValueChanged(.never))
        waitFor(!coordinator.alertShown.isEmpty)

        let neverLockAlert = try XCTUnwrap(coordinator.alertShown.last)
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
    @MainActor
    func test_receive_sessionTimeoutValueChanged_noAlert() {
        XCTAssertEqual(subject.state.sessionTimeoutValue, .immediately)

        let account = Account.fixture()
        authRepository.activeAccount = account
        subject.receive(.sessionTimeoutValueChanged(.fiveMinutes))
        waitFor(subject.state.sessionTimeoutValue == .fiveMinutes)
    }

    /// `receive(_:)` with `sessionTimeoutValueChanged(:)` shows an alert when the user
    /// enters a value that exceeds the policy limit. It also sets the user's timeout to the policy limit.
    @MainActor
    func test_receive_sessionTimeoutValueChanged_policy_exceedsLimit() throws {
        let account = Account.fixture()
        authRepository.activeAccount = account
        subject.state.isTimeoutPolicyEnabled = true
        subject.state.policyTimeoutValue = 1

        subject.receive(.sessionTimeoutValueChanged(.fourHours))

        waitFor(!coordinator.alertShown.isEmpty)

        XCTAssertEqual(authRepository.vaultTimeout["1"], .oneMinute)
        XCTAssertEqual(coordinator.alertShown, [.timeoutExceedsPolicyLengthAlert()])
    }

    /// `receive(_:)` with `sessionTimeoutValueChanged(:)` shows an alert when the user
    /// enters a value that exceeds the policy limit. It surfaces any error when setting the policy value.
    @MainActor
    func test_receive_sessionTimeoutValueChanged_policy_exceedsLimit_error() throws {
        let account = Account.fixture()
        authRepository.activeAccount = account
        authRepository.setVaultTimeoutError = BitwardenTestError.example
        subject.state.isTimeoutPolicyEnabled = true
        subject.state.policyTimeoutValue = 60

        subject.receive(.sessionTimeoutValueChanged(.fourHours))

        waitFor(errorReporter.errors.last as? BitwardenTestError == BitwardenTestError.example)
    }

    /// `receive(_:)` with `showSetUpUnlock(:)` has the coordinator navigate to the vault unlock
    /// setup screen.
    @MainActor
    func test_receive_showSetUpUnlock() throws {
        subject.receive(.showSetUpUnlock)

        XCTAssertEqual(coordinator.routes, [.vaultUnlockSetup])
    }

    /// `receive(_:)` with `.twoStepLoginPressed` shows the two step login alert.
    @MainActor
    func test_receive_twoStepLoginPressed() async throws {
        subject.receive(.twoStepLoginPressed)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
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

    /// The vault timeout action is refreshed after turning off pin unlock to handle users without
    /// a master password when a lock timeout action may not be available.
    @MainActor
    func test_refreshVaultTimeoutAction_withoutMasterPassword_pinOff() async {
        authRepository.activeAccount = .fixtureWithTdeNoPassword()
        authRepository.sessionTimeoutAction["1"] = .lock
        subject.state.isUnlockWithPINCodeOn = true

        await subject.perform(.appeared)

        authRepository.sessionTimeoutAction["1"] = .logout

        await subject.perform(.toggleUnlockWithPINCode(false))

        XCTAssertEqual(subject.state.sessionTimeoutAction, .logout)
    }

    /// The vault timeout action is refreshed after turning off biometrics unlock to handle users
    /// without a master password when a lock timeout action may not be available.
    @MainActor
    func test_refreshVaultTimeoutAction_withoutMasterPassword_biometricsOff() async {
        authRepository.activeAccount = .fixtureWithTdeNoPassword()
        authRepository.sessionTimeoutAction["1"] = .lock
        subject.state.biometricUnlockStatus = .available(.faceID, enabled: true)

        await subject.perform(.appeared)
        waitFor { subject.state.sessionTimeoutAction == .lock }

        authRepository.sessionTimeoutAction["1"] = .logout

        await subject.perform(.toggleUnlockWithBiometrics(false))

        XCTAssertEqual(subject.state.sessionTimeoutAction, .logout)
    }

    /// `state.twoStepLoginUrl` is initialized with the correct value.
    @MainActor
    func test_twoStepLoginUrl() async throws {
        subject.receive(.twoStepLoginPressed)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(subject.state.twoStepLoginUrl, URL.example)
    }
} // swiftlint:disable:this file_length
