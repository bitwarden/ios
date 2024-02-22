import SwiftUI
import XCTest

@testable import BitwardenShared

class VaultUnlockProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appExtensionDelegate: MockAppExtensionDelegate!
    var authRepository: MockAuthRepository!
    var biometricsRepository: MockBiometricsRepository!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var subject: VaultUnlockProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockAppExtensionDelegate()
        authRepository = MockAuthRepository()
        biometricsRepository = MockBiometricsRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()

        subject = VaultUnlockProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                biometricsRepository: biometricsRepository,
                errorReporter: errorReporter,
                stateService: stateService
            ),
            state: VaultUnlockState(account: .fixture())
        )
    }

    override func tearDown() {
        super.tearDown()

        appExtensionDelegate = nil
        authRepository = nil
        biometricsRepository = nil
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(.appeared)` with a biometrics status error yields `BiometricUnlockStatus.unavailable`.
    func test_perform_appeared_biometricUnlockStatus_error() async {
        stateService.activeAccount = .fixture()
        struct FetchError: Error {}
        biometricsRepository.biometricUnlockStatus = .failure(FetchError())
        await subject.perform(.appeared)

        XCTAssertEqual([], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertTrue(subject.state.profileSwitcherState.showsAddAccount)
        XCTAssertEqual(subject.state.biometricUnlockStatus, .notAvailable)
    }

    /// `perform(.appeared)` with a biometrics status error yields `BiometricUnlockStatus.unavailable`.
    func test_perform_appeared_biometricUnlockStatus_success() async {
        stateService.activeAccount = .fixture()
        struct FetchError: Error {}
        let expectedStatus = BiometricsUnlockStatus.available(.touchID, enabled: true, hasValidIntegrity: false)
        biometricsRepository.biometricUnlockStatus = .success(expectedStatus)
        await subject.perform(.appeared)

        XCTAssertEqual([], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertTrue(subject.state.profileSwitcherState.showsAddAccount)
        XCTAssertEqual(subject.state.biometricUnlockStatus, expectedStatus)
    }

    /// `perform(.appeared)` without profiles for the profile switcher.
    func test_perform_appeared_empty() async {
        await subject.perform(.appeared)

        XCTAssertEqual(
            subject.state.profileSwitcherState,
            ProfileSwitcherState.empty()
        )
    }

    /// `perform(.appeared)` with an active account and accounts should yield a profile switcher state.
    func test_perform_appeared_profiles_single_active() async {
        let profile = ProfileSwitcherItem.fixture()
        authRepository.profileSwitcherState = .init(
            accounts: [profile],
            activeAccountId: profile.userId,
            allowLockAndLogout: true,
            isVisible: false
        )
        await subject.perform(.appeared)

        XCTAssertEqual([], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertEqual(profile, subject.state.profileSwitcherState.activeAccountProfile)
        XCTAssertTrue(subject.state.profileSwitcherState.showsAddAccount)
    }

    /// `perform(.appeared)` refreshes the profile switcher and disables add account when running
    /// in the app extension.
    func test_perform_appeared_refreshProfile_inAppExtension() async {
        let profile = ProfileSwitcherItem.fixture()
        authRepository.profileSwitcherState = .init(
            accounts: [profile],
            activeAccountId: nil,
            allowLockAndLogout: true,
            isVisible: false
        )
        appExtensionDelegate.isInAppExtension = true

        await subject.perform(.appeared)

        XCTAssertEqual(
            subject.state.profileSwitcherState,
            ProfileSwitcherState(
                accounts: [profile],
                activeAccountId: nil,
                allowLockAndLogout: true,
                isVisible: false,
                shouldAlwaysHideAddAccount: true
            )
        )
    }

    /// `perform(.appeared)` sets the state property for whether the app is running in an extension.
    func test_perform_appeared_setsIsInAppExtension() async {
        appExtensionDelegate.isInAppExtension = true
        await subject.perform(.appeared)
        XCTAssertTrue(subject.state.isInAppExtension)

        appExtensionDelegate.isInAppExtension = false
        await subject.perform(.appeared)
        XCTAssertFalse(subject.state.isInAppExtension)
    }

    /// `perform(.appeared)` with an active account and accounts should yield a profile switcher state.
    func test_perform_appeared_unlockAttempts() async {
        stateService.activeAccount = .fixture()
        await stateService.setUnsuccessfulUnlockAttempts(3)
        await subject.perform(.appeared)

        XCTAssertEqual(3, subject.state.unsuccessfulUnlockAttemptsCount)
    }

    /// `perform(.appeared)`
    /// No active account and accounts should yield a profile switcher state without an active account.
    func test_perform_refresh_profiles_single_notActive() async {
        let profile = ProfileSwitcherItem.fixture()
        authRepository.profileSwitcherState = .init(
            accounts: [profile],
            activeAccountId: nil,
            allowLockAndLogout: true,
            isVisible: false
        )
        await subject.perform(.appeared)

        XCTAssertEqual(
            subject.state.profileSwitcherState,
            ProfileSwitcherState(
                accounts: [profile],
                activeAccountId: nil,
                allowLockAndLogout: true,
                isVisible: false
            )
        )
    }

    /// `perform(.appeared)`:
    ///  An active account and multiple accounts should yield a profile switcher state.
    func test_perform_refresh_profiles_single_multiAccount() async {
        let profile = ProfileSwitcherItem.fixture()
        let alternate = ProfileSwitcherItem.fixture()
        authRepository.profileSwitcherState = .init(
            accounts: [profile, alternate],
            activeAccountId: profile.userId,
            allowLockAndLogout: true,
            isVisible: false
        )
        await subject.perform(.appeared)

        XCTAssertEqual([alternate], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertEqual(profile, subject.state.profileSwitcherState.activeAccountProfile)
        XCTAssertTrue(subject.state.profileSwitcherState.showsAddAccount)
    }

    /// `perform(.profileSwitcher(.rowAppeared))` should not update the state for add Account
    func test_perform_rowAppeared_add() async {
        let profile = ProfileSwitcherItem.fixture()
        let alternate = ProfileSwitcherItem.fixture()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, alternate],
            activeAccountId: profile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        await subject.perform(.profileSwitcher(.rowAppeared(.addAccount)))

        XCTAssertFalse(subject.state.profileSwitcherState.hasSetAccessibilityFocus)
    }

    /// `perform(.profileSwitcher(.rowAppeared))` should not update the state for alternate account
    func test_perform_rowAppeared_alternate() async {
        let profile = ProfileSwitcherItem.fixture()
        let alternate = ProfileSwitcherItem.fixture()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, alternate],
            activeAccountId: profile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        await subject.perform(.profileSwitcher(.rowAppeared(.alternate(alternate))))

        XCTAssertFalse(subject.state.profileSwitcherState.hasSetAccessibilityFocus)
    }

    /// `perform(.profileSwitcher(.rowAppeared))` should update the state for active account
    func test_perform_rowAppeared_active() {
        let profile = ProfileSwitcherItem.fixture()
        let alternate = ProfileSwitcherItem.fixture()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, alternate],
            activeAccountId: profile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        let task = Task {
            await subject.perform(.profileSwitcher(.rowAppeared(.active(profile))))
        }

        waitFor(subject.state.profileSwitcherState.hasSetAccessibilityFocus, timeout: 0.5)
        task.cancel()
        XCTAssertTrue(subject.state.profileSwitcherState.hasSetAccessibilityFocus)
    }

    /// `perform(_:)` with `.unlockVault` attempts to unlock the vault with the entered password.
    func test_perform_unlockVault() async throws {
        stateService.activeAccount = Account.fixture()
        stateService.pinProtectedUserKeyValue["1"] = "123"
        stateService.pinKeyEncryptedUserKeyValue["1"] = "123"
        subject.state.masterPassword = "password"

        await subject.perform(.unlockVault)

        XCTAssertEqual(authRepository.pinProtectedUserKey, "123")
        XCTAssertEqual(authRepository.encryptedPin, "123")
        XCTAssertEqual(authRepository.unlockVaultPassword, "password")
        XCTAssertEqual(coordinator.events.last, .didCompleteAuth)
    }

    /// `perform(_:)` with `.unlockVault` shows the KDF warning in an extension if the KDF memory is
    /// potentially too high.
    func test_perform_unlockVault_extensionKdfWarning() async throws {
        appExtensionDelegate.isInAppExtension = true
        stateService.activeAccount = .fixture(profile: .fixture(kdfMemory: 50, kdfType: .argon2id))
        subject.state.masterPassword = "password"

        await subject.perform(.unlockVault)

        XCTAssertEqual(coordinator.alertShown, [.extensionKdfMemoryWarning {}])

        let alert = coordinator.alertShown.last
        try await alert?.tapAction(title: Localizations.continue)

        XCTAssertEqual(authRepository.unlockVaultPassword, "password")
        XCTAssertEqual(coordinator.events.last, .didCompleteAuth)
    }

    /// `perform(_:)` with `.unlockVault` shows an alert if the master password is empty.
    func test_perform_unlockVault_InputValidationError_noPassword() async throws {
        subject.state.unlockMethod = .password
        await subject.perform(.unlockVault)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(
            alert,
            Alert.inputValidationAlert(error: InputValidationError(
                message: Localizations.validationFieldRequired(Localizations.masterPassword)
            ))
        )
    }

    /// `perform(_:)` with `.unlockVault` shows an alert if the PIN is empty.
    func test_perform_unlockVault_InputValidationError_noPIN() async throws {
        subject.state.unlockMethod = .pin
        await subject.perform(.unlockVault)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(
            alert,
            Alert.inputValidationAlert(error: InputValidationError(
                message: Localizations.validationFieldRequired(Localizations.pin)
            ))
        )
    }

    /// `perform(_:)` with `.unlockVault` shows an alert if the master password was incorrect.
    func test_perform_unlockVault_invalidPasswordError() async throws {
        subject.state.masterPassword = "password"

        struct VaultUnlockError: Error {}
        authRepository.unlockWithPasswordResult = .failure(VaultUnlockError())

        await subject.perform(.unlockVault)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, Localizations.anErrorHasOccurred)
        XCTAssertEqual(alert.message, Localizations.invalidMasterPassword)
    }

    /// `perform(_:)` with `.unlockVault` displays an alert a maximum of 5 times if the master password was incorrect.
    ///  After the 5th attempt, it logs the user out.
    func test_perform_unlockVault_invalidPassword_logout() async throws { // swiftlint:disable:this function_body_length
        subject.state.masterPassword = "password"
        stateService.activeAccount = .fixture()
        XCTAssertEqual(subject.state.unsuccessfulUnlockAttemptsCount, 0)
        struct VaultUnlockError: Error {}
        authRepository.unlockWithPasswordResult = .failure(VaultUnlockError())

        // 1st unsuccessful attempt
        await subject.perform(.unlockVault)
        var alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, Localizations.anErrorHasOccurred)
        XCTAssertEqual(alert.message, Localizations.invalidMasterPassword)
        XCTAssertEqual(subject.state.unsuccessfulUnlockAttemptsCount, 1)
        var attemptsInUserDefaults = await stateService.getUnsuccessfulUnlockAttempts()
        XCTAssertEqual(attemptsInUserDefaults, 1)
        await alert.alertActions[0].handler?(alert.alertActions[0], [])
        XCTAssertFalse(authRepository.logoutCalled)
        XCTAssertNotEqual(coordinator.routes.last, .landing)

        // 2nd unsuccessful attempts
        await subject.perform(.unlockVault)
        XCTAssertEqual(subject.state.unsuccessfulUnlockAttemptsCount, 2)
        attemptsInUserDefaults = await stateService.getUnsuccessfulUnlockAttempts()
        XCTAssertEqual(attemptsInUserDefaults, 2)
        alert = try coordinator.unwrapLastRouteAsAlert()
        await alert.alertActions[0].handler?(alert.alertActions[0], [])
        XCTAssertFalse(authRepository.logoutCalled)
        XCTAssertNotEqual(coordinator.routes.last, .landing)

        // 3rd unsuccessful attempts
        await subject.perform(.unlockVault)
        XCTAssertEqual(subject.state.unsuccessfulUnlockAttemptsCount, 3)
        attemptsInUserDefaults = await stateService.getUnsuccessfulUnlockAttempts()
        XCTAssertEqual(attemptsInUserDefaults, 3)
        alert = try coordinator.unwrapLastRouteAsAlert()
        await alert.alertActions[0].handler?(alert.alertActions[0], [])
        XCTAssertFalse(authRepository.logoutCalled)
        XCTAssertNotEqual(coordinator.routes.last, .landing)

        // 4th unsuccessful attempts
        await subject.perform(.unlockVault)
        XCTAssertEqual(subject.state.unsuccessfulUnlockAttemptsCount, 4)
        attemptsInUserDefaults = await stateService.getUnsuccessfulUnlockAttempts()
        XCTAssertEqual(attemptsInUserDefaults, 4)
        alert = try coordinator.unwrapLastRouteAsAlert()
        await alert.alertActions[0].handler?(alert.alertActions[0], [])
        XCTAssertFalse(authRepository.logoutCalled)
        XCTAssertNotEqual(coordinator.routes.last, .landing)

        // 5th unsuccessful attempts
        await subject.perform(.unlockVault)
        // after 5th unsuccessful attempts, we log user out and reset the count to 0.
        XCTAssertEqual(subject.state.unsuccessfulUnlockAttemptsCount, 0)
        attemptsInUserDefaults = await stateService.getUnsuccessfulUnlockAttempts()
        XCTAssertEqual(attemptsInUserDefaults, 0)
        await alert.alertActions[0].handler?(alert.alertActions[0], [])
        attemptsInUserDefaults = await stateService.getUnsuccessfulUnlockAttempts()
        XCTAssertEqual(attemptsInUserDefaults, 0)
        XCTAssertEqual(
            coordinator.events.last,
            .action(
                .logout(userId: nil, userInitiated: true)
            )
        )
    }

    /// `perform(_:)` with `.unlockVault` logs error if force logout fails after the 5th unsuccessful attempts.
    func test_perform_unlockVault_invalidPassword() async throws {
        subject.state.masterPassword = "password"
        stateService.activeAccount = .fixtureAccountLogin()
        subject.state.unsuccessfulUnlockAttemptsCount = 4
        await stateService.setUnsuccessfulUnlockAttempts(5)
        XCTAssertEqual(subject.state.unsuccessfulUnlockAttemptsCount, 4)
        struct VaultUnlockError: Error {}
        authRepository.unlockWithPasswordResult = .failure(VaultUnlockError())

        // 5th unsuccessful attempts
        await subject.perform(.unlockVault)

        XCTAssertEqual(
            coordinator.events.last,
            .action(
                .logout(userId: nil, userInitiated: true)
            )
        )
    }

    /// `perform(_:)` with `.unlockVault` successful unlocking vault resets the `unsuccessfulUnlockAttemptsCount`.
    func test_perform_unlockVault_validPassword_resetsFailedUnlockAttemptsCount() async throws {
        subject.state.masterPassword = "password"
        XCTAssertEqual(subject.state.unsuccessfulUnlockAttemptsCount, 0)
        struct VaultUnlockError: Error {}
        authRepository.unlockWithPasswordResult = .failure(VaultUnlockError())
        stateService.activeAccount = .fixture()
        var attemptsInUserDefaults = await stateService.getUnsuccessfulUnlockAttempts()
        XCTAssertEqual(attemptsInUserDefaults, 0)

        await subject.perform(.unlockVault)
        XCTAssertEqual(subject.state.unsuccessfulUnlockAttemptsCount, 1)
        attemptsInUserDefaults = await stateService.getUnsuccessfulUnlockAttempts()
        XCTAssertEqual(attemptsInUserDefaults, 1)
        await subject.perform(.unlockVault)
        XCTAssertEqual(subject.state.unsuccessfulUnlockAttemptsCount, 2)
        attemptsInUserDefaults = await stateService.getUnsuccessfulUnlockAttempts()
        XCTAssertEqual(attemptsInUserDefaults, 2)

        authRepository.unlockWithPasswordResult = .success(())
        await subject.perform(.unlockVault)
        XCTAssertEqual(subject.state.unsuccessfulUnlockAttemptsCount, 0)
        attemptsInUserDefaults = await stateService.getUnsuccessfulUnlockAttempts()
        XCTAssertEqual(attemptsInUserDefaults, 0)
    }

    /// `perform(_:)` with `.unlockVaultWithBiometrics` shows the KDF warning in an extension if the
    /// KDF memory is potentially too high.
    func test_perform_unlockWithBiometrics_extensionKdfWarning() async throws {
        appExtensionDelegate.isInAppExtension = true
        authRepository.unlockVaultWithBiometricsResult = .success(())
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.faceID, enabled: true, hasValidIntegrity: true)
        )
        stateService.activeAccount = .fixture(profile: .fixture(kdfMemory: 50, kdfType: .argon2id))
        subject.state.biometricUnlockStatus = .available(.touchID, enabled: true, hasValidIntegrity: true)

        await subject.perform(.unlockVaultWithBiometrics)

        XCTAssertEqual(coordinator.alertShown, [.extensionKdfMemoryWarning {}])

        let alert = coordinator.alertShown.last
        try await alert?.tapAction(title: Localizations.continue)

        XCTAssertEqual(coordinator.events.last, .didCompleteAuth)
    }

    /// `perform(_:)` with `.unlockWithBiometrics` requires a set user preference.
    func test_perform_unlockWithBiometrics_noAccount() async throws {
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.faceID, enabled: true, hasValidIntegrity: true)
        )
        authRepository.unlockVaultWithBiometricsResult = .failure(StateServiceError.noActiveAccount)
        subject.state.biometricUnlockStatus = .available(.touchID, enabled: true, hasValidIntegrity: true)

        await subject.perform(.unlockVaultWithBiometrics)
        let route = try XCTUnwrap(coordinator.routes.last)
        XCTAssertEqual(route, .landing)
    }

    /// `perform(_:)` with `.unlockWithBiometrics` requires a set user preference.
    func test_perform_unlockWithBiometrics_notAvailable() async throws {
        biometricsRepository.biometricUnlockStatus = .success(.notAvailable)
        authRepository.unlockVaultWithBiometricsResult = .success(())
        subject.state.biometricUnlockStatus = .available(.touchID, enabled: true, hasValidIntegrity: true)

        await subject.perform(.unlockVaultWithBiometrics)
        XCTAssertNil(coordinator.routes.last)
    }

    /// `perform(_:)` with `.unlockWithBiometrics` requires a set user preference.
    func test_perform_unlockWithBiometrics_notEnabled() async throws {
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.touchID, enabled: false, hasValidIntegrity: true)
        )
        authRepository.unlockVaultWithBiometricsResult = .success(())
        subject.state.biometricUnlockStatus = .available(.touchID, enabled: true, hasValidIntegrity: true)

        await subject.perform(.unlockVaultWithBiometrics)
        XCTAssertNil(coordinator.routes.last)
    }

    /// `perform(_:)` with `.unlockWithBiometrics` requires a set user preference.
    func test_perform_unlockWithBiometrics_invalidIntegrity() async throws {
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.touchID, enabled: true, hasValidIntegrity: false)
        )
        authRepository.unlockVaultWithBiometricsResult = .success(())
        subject.state.biometricUnlockStatus = .available(.touchID, enabled: true, hasValidIntegrity: true)

        await subject.perform(.unlockVaultWithBiometrics)
        XCTAssertNil(coordinator.routes.last)
    }

    /// `perform(_:)` with `.unlockWithBiometrics` requires successful biometrics.
    func test_perform_unlockWithBiometrics_authRepoError() async throws {
        stateService.activeAccount = .fixture()
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.touchID, enabled: true, hasValidIntegrity: true)
        )
        struct BiometricsError: Error {}
        authRepository.unlockVaultWithBiometricsResult = .failure(BiometricsError())

        await subject.perform(.unlockVaultWithBiometrics)
        XCTAssertNil(coordinator.routes.last)
        XCTAssertEqual(1, subject.state.unsuccessfulUnlockAttemptsCount)
    }

    /// `perform(_:)` with `.unlockWithBiometrics` requires successful biometrics.
    func test_perform_unlockWithBiometrics_authRepoError_maxAttempts() async throws {
        stateService.activeAccount = .fixture()
        subject.state.unsuccessfulUnlockAttemptsCount = 4
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.touchID, enabled: true, hasValidIntegrity: true)
        )
        struct BiometricsError: Error {}
        authRepository.unlockVaultWithBiometricsResult = .failure(BiometricsError())

        await subject.perform(.unlockVaultWithBiometrics)
        XCTAssertEqual(0, subject.state.unsuccessfulUnlockAttemptsCount)
        XCTAssertEqual(
            coordinator.events.last,
            .action(
                .logout(userId: nil, userInitiated: true)
            )
        )
    }

    /// `perform(_:)` with `.unlockWithBiometrics` requires successful biometrics.
    func test_perform_unlockWithBiometrics_authRepoError_getAuthKeyFailed() async throws {
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.touchID, enabled: true, hasValidIntegrity: true)
        )
        authRepository.unlockVaultWithBiometricsResult = .failure(BiometricsServiceError.getAuthKeyFailed)
        authRepository.allowBiometricUnlockResult = .success(())

        await subject.perform(.unlockVaultWithBiometrics)
        XCTAssertEqual(authRepository.allowBiometricUnlock, false)
        XCTAssertNil(coordinator.routes.last)
    }

    /// `perform(_:)` with `.unlockWithBiometrics` handles user cancellation.
    func test_perform_unlockWithBiometrics_userCancelled() async throws {
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.touchID, enabled: true, hasValidIntegrity: true)
        )
        authRepository.unlockVaultWithBiometricsResult = .failure(BiometricsServiceError.biometryCancelled)
        authRepository.allowBiometricUnlockResult = .success(())

        await subject.perform(.unlockVaultWithBiometrics)
        XCTAssertNil(authRepository.allowBiometricUnlock)
        XCTAssertNil(coordinator.routes.last)
    }

    /// `perform(_:)` with `.unlockWithBiometrics` requires successful biometrics.
    func test_perform_unlockWithBiometrics_success() async throws {
        subject.state.unsuccessfulUnlockAttemptsCount = 3
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.faceID, enabled: true, hasValidIntegrity: true)
        )
        authRepository.unlockVaultWithBiometricsResult = .success(())

        await subject.perform(.unlockVaultWithBiometrics)
        let event = try XCTUnwrap(coordinator.events.last)
        XCTAssertEqual(event, .didCompleteAuth)
        XCTAssertEqual(0, subject.state.unsuccessfulUnlockAttemptsCount)
    }

    /// `receive(_:)` with `.masterPasswordChanged` updates the state to reflect the changes.
    func test_receive_masterPasswordChanged() {
        subject.state.masterPassword = ""

        subject.receive(.masterPasswordChanged("password"))
        XCTAssertEqual(subject.state.masterPassword, "password")
    }

    /// `receive(_:)` with `.morePressed` navigates to the login options screen and allows the user
    /// to logout.
    func test_receive_morePressed_logout() async throws {
        subject.receive(.morePressed)

        let optionsAlert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(optionsAlert.title, Localizations.options)
        XCTAssertNil(optionsAlert.message)
        XCTAssertEqual(optionsAlert.preferredStyle, .actionSheet)
        XCTAssertEqual(optionsAlert.alertActions.count, 2)
        XCTAssertEqual(optionsAlert.alertActions[0].title, Localizations.logOut)
        XCTAssertEqual(optionsAlert.alertActions[1].title, Localizations.cancel)

        await optionsAlert.alertActions[0].handler?(optionsAlert.alertActions[0], [])

        let logoutConfirmationAlert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(logoutConfirmationAlert.title, Localizations.logOut)
        XCTAssertEqual(logoutConfirmationAlert.message, Localizations.logoutConfirmation)
        XCTAssertEqual(logoutConfirmationAlert.preferredStyle, .alert)
        XCTAssertEqual(logoutConfirmationAlert.alertActions.count, 2)
        XCTAssertEqual(logoutConfirmationAlert.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(logoutConfirmationAlert.alertActions[1].title, Localizations.cancel)

        await logoutConfirmationAlert.alertActions[0].handler?(optionsAlert.alertActions[0], [])

        XCTAssertEqual(
            coordinator.events.last,
            .action(
                .logout(userId: nil, userInitiated: true)
            )
        )
    }

    /// `receive(_:)` with `.morePressed` navigates to the login options screen and allows the user
    /// to logout.
    func test_receive_morePressed_logout_nextAccount() async throws {
        stateService.accounts = [
            .fixture(),
            .fixtureAccountLogin(),
        ]
        stateService.activeAccount = .fixture()
        subject.receive(.morePressed)

        let optionsAlert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(optionsAlert.title, Localizations.options)
        XCTAssertNil(optionsAlert.message)
        XCTAssertEqual(optionsAlert.preferredStyle, .actionSheet)
        XCTAssertEqual(optionsAlert.alertActions.count, 2)
        XCTAssertEqual(optionsAlert.alertActions[0].title, Localizations.logOut)
        XCTAssertEqual(optionsAlert.alertActions[1].title, Localizations.cancel)

        await optionsAlert.alertActions[0].handler?(optionsAlert.alertActions[0], [])

        let logoutConfirmationAlert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(logoutConfirmationAlert.title, Localizations.logOut)
        XCTAssertEqual(logoutConfirmationAlert.message, Localizations.logoutConfirmation)
        XCTAssertEqual(logoutConfirmationAlert.preferredStyle, .alert)
        XCTAssertEqual(logoutConfirmationAlert.alertActions.count, 2)
        XCTAssertEqual(logoutConfirmationAlert.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(logoutConfirmationAlert.alertActions[1].title, Localizations.cancel)

        await logoutConfirmationAlert.alertActions[0].handler?(optionsAlert.alertActions[0], [])

        XCTAssertEqual(
            coordinator.events.last,
            .action(
                .logout(userId: nil, userInitiated: true)
            )
        )
    }

    /// `receive(_:)` with `.revealMasterPasswordFieldPressed` updates the state to reflect the changes.
    func test_receive_revealMasterPasswordFieldPressed() {
        subject.state.isMasterPasswordRevealed = false
        subject.receive(.revealMasterPasswordFieldPressed(true))
        XCTAssertTrue(subject.state.isMasterPasswordRevealed)

        subject.receive(.revealMasterPasswordFieldPressed(false))
        XCTAssertFalse(subject.state.isMasterPasswordRevealed)
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` shows the alert and allows the user to
    /// lock the selected account.
    func test_receive_accountLongPressed_lock() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture(userId: "1")
        let otherProfile = ProfileSwitcherItem.fixture(isUnlocked: true, userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        authRepository.activeAccount = Account.fixture(profile: .fixture(userId: "1"))

        await subject.perform(.profileSwitcher(.accountLongPressed(otherProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to lock the account.
        let lockAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await lockAction.handler?(lockAction, [])

        // Verify the results.
        XCTAssertEqual(coordinator.events.last, .action(.lockVault(userId: otherProfile.userId)))
        XCTAssertEqual(subject.state.toast?.text, Localizations.accountLockedSuccessfully)
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` records any errors from locking the account.
    func test_receive_accountLongPressed_lock_error() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture()
        let otherProfile = ProfileSwitcherItem.fixture(isUnlocked: true, userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        authRepository.activeAccount = nil

        await subject.perform(.profileSwitcher(.accountLongPressed(otherProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to lock the account.
        let lockAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await lockAction.handler?(lockAction, [])

        // Verify the results.
        XCTAssertEqual(errorReporter.errors.last as? StateServiceError, .noActiveAccount)
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` shows the alert and allows the user to
    /// log out of the selected account, which navigates back to the landing page for the active account.
    func test_receive_accountLongPressed_logout_activeAccount() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture()
        let otherProfile = ProfileSwitcherItem.fixture(userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        authRepository.activeAccount = .fixture()

        await subject.perform(.profileSwitcher(.accountLongPressed(activeProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to log out from the account.
        let logoutAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await logoutAction.handler?(logoutAction, [])

        // Confirm logging out on the second alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Verify the results.
        XCTAssertEqual(
            coordinator.events.last,
            .action(
                .logout(userId: activeProfile.userId, userInitiated: true)
            )
        )
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` shows the alert and allows the user to
    /// log out of the selected account, which triggers an account switch.
    func test_receive_accountLongPressed_logout_activeAccount_withAlternate() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture()
        let otherProfile = ProfileSwitcherItem.fixture(userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        authRepository.activeAccount = .fixture()
        stateService.accounts = [
            .fixture(
                profile: .fixture(
                    userId: "42"
                )
            ),
        ]

        await subject.perform(.profileSwitcher(.accountLongPressed(activeProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to log out from the account.
        let logoutAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await logoutAction.handler?(logoutAction, [])

        // Confirm logging out on the second alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Verify the results.
        XCTAssertEqual(
            coordinator.events.last,
            .action(
                .logout(userId: activeProfile.userId, userInitiated: true)
            )
        )
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` shows the alert and allows the user to
    /// log out of the selected account, which displays a toast.
    func test_receive_accountLongPressed_logout_otherAccount() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture()
        let otherProfile = ProfileSwitcherItem.fixture(userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        authRepository.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        authRepository.activeAccount = .fixture()
        await subject.perform(.profileSwitcher(.accountLongPressed(otherProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to log out from the account.
        let logoutAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await logoutAction.handler?(logoutAction, [])

        // Confirm logging out on the second alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Verify the results.
        XCTAssertEqual(
            coordinator.events.last,
            .action(.logout(userId: otherProfile.userId, userInitiated: true))
        )
        XCTAssertEqual(subject.state.toast?.text, Localizations.accountLoggedOutSuccessfully)
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` records any errors from logging out the
    /// account.
    func test_receive_accountLongPressed_logout_error() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture()
        let otherProfile = ProfileSwitcherItem.fixture(userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        authRepository.activeAccount = nil

        await subject.perform(.profileSwitcher(.accountLongPressed(otherProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to log out from the account.
        let logoutAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await logoutAction.handler?(logoutAction, [])

        // Confirm logging out on the second alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Verify the results.
        XCTAssertEqual(errorReporter.errors.last as? StateServiceError, .noActiveAccount)
    }

    /// `receive(_:)` with `.profileSwitcher(.accountPressed)` updates the state to reflect the changes.
    func test_receive_accountPressed_active_unlocked() {
        let profile = ProfileSwitcherItem.fixture()
        authRepository.profileSwitcherState = .init(
            accounts: [profile],
            activeAccountId: profile.userId,
            allowLockAndLogout: true,
            isVisible: false
        )

        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile],
            activeAccountId: profile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        let task = Task {
            await subject.perform(.profileSwitcher(.accountPressed(profile)))
        }
        waitFor(!subject.state.profileSwitcherState.isVisible)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(coordinator.events, [])
    }

    /// `receive(_:)` with `.profileSwitcher(.accountPressed)` updates the state to reflect the changes.
    func test_receive_accountPressed_active_locked() {
        let profile = ProfileSwitcherItem.fixture(isUnlocked: false)
        let account = Account.fixture(profile: .fixture(
            userId: profile.userId
        ))
        authRepository.profileSwitcherState = .init(
            accounts: [profile],
            activeAccountId: profile.userId,
            allowLockAndLogout: true,
            isVisible: false
        )
        authRepository.accountForItemResult = .success(account)
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile],
            activeAccountId: profile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        let task = Task {
            await subject.perform(.profileSwitcher(.accountPressed(profile)))
        }
        waitFor(!subject.state.profileSwitcherState.isVisible)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(coordinator.events, [])
    }

    /// `receive(_:)` with `.profileSwitcher(.accountPressed)` updates the state to reflect the changes.
    func test_receive_accountPressed_alternateUnlocked() {
        let profile = ProfileSwitcherItem.fixture(isUnlocked: true)
        let active = ProfileSwitcherItem.fixture()
        let account = Account.fixture(profile: .fixture(
            userId: profile.userId
        ))
        authRepository.profileSwitcherState = .init(
            accounts: [active, profile],
            activeAccountId: active.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        authRepository.accountForItemResult = .success(account)
        authRepository.isLockedResult = .success(false)
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, active],
            activeAccountId: active.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        let task = Task {
            await subject.perform(.profileSwitcher(.accountPressed(profile)))
        }
        waitFor(!coordinator.events.isEmpty)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(coordinator.events, [.action(.switchAccount(isAutomatic: false, userId: profile.userId))])
    }

    /// `receive(_:)` with `.profileSwitcher(.accountPressed)` updates the state to reflect the changes.
    func test_receive_accountPressed_alternateLocked() {
        let profile = ProfileSwitcherItem.fixture(isUnlocked: false)
        let active = ProfileSwitcherItem.fixture()
        let account = Account.fixture(profile: .fixture(
            userId: profile.userId
        ))
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, active],
            activeAccountId: active.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        authRepository.accountForItemResult = .success(account)
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, active],
            activeAccountId: active.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        let task = Task {
            await subject.perform(.profileSwitcher(.accountPressed(profile)))
        }
        waitFor(!coordinator.events.isEmpty)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(coordinator.events, [.action(.switchAccount(isAutomatic: false, userId: profile.userId))])
    }

    /// `receive(_:)` with `.profileSwitcher(.accountPressed)` updates the state to reflect the changes.
    func test_receive_accountPressed_noMatch() {
        let profile = ProfileSwitcherItem.fixture()
        let active = ProfileSwitcherItem.fixture()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [active],
            activeAccountId: active.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, active],
            activeAccountId: active.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        let task = Task {
            await subject.perform(.profileSwitcher(.accountPressed(profile)))
        }
        waitFor(!coordinator.events.isEmpty)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(coordinator.events, [.action(.switchAccount(isAutomatic: false, userId: profile.userId))])
    }

    /// `receive(_:)` with `.profileSwitcher(.addAccountPressed)` updates the state to reflect the changes.
    func test_receive_addAccountPressed() {
        let active = ProfileSwitcherItem.fixture()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [active],
            activeAccountId: active.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        let task = Task {
            await subject.perform(.profileSwitcher(.addAccountPressed))
        }
        waitFor(!coordinator.routes.isEmpty)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(coordinator.routes, [.landing])
    }

    /// `receive(_:)` with `.profileSwitcher(.backgroundPressed)` updates the state to reflect the changes.
    func test_receive_backgroundPressed() {
        let active = ProfileSwitcherItem.fixture()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [active],
            activeAccountId: active.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        let task = Task {
            subject.receive(.profileSwitcher(.backgroundPressed))
        }
        waitFor(!subject.state.profileSwitcherState.isVisible)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(coordinator.routes, [])
    }

    /// `receive(_:)` with `.cancelPressed` notifies the delegate that cancel was pressed.
    func test_receive_cancelPressed() {
        subject.receive(.cancelPressed)

        XCTAssertTrue(appExtensionDelegate.didCancelCalled)
    }

    /// `receive(_:)` with `.requestedProfileSwitcher(visible:)` updates the state to reflect the changes.
    func test_receive_requestedProfileSwitcherVisible_false() {
        let active = ProfileSwitcherItem.fixture()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [active],
            activeAccountId: active.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        let task = Task {
            subject.receive(.profileSwitcher(.requestedProfileSwitcher(visible: false)))
        }
        waitFor(!subject.state.profileSwitcherState.isVisible)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.requestedProfileSwitcher(visible:)` updates the state to reflect the changes.
    func test_receive_requestedProfileSwitcherVisible_true() {
        let active = ProfileSwitcherItem.fixture()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [active],
            activeAccountId: active.userId,
            allowLockAndLogout: true,
            isVisible: false
        )

        let task = Task {
            subject.receive(.profileSwitcher(.requestedProfileSwitcher(visible: true)))
        }
        waitFor(subject.state.profileSwitcherState.isVisible)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.profileSwitcher(.scrollOffset)` updates the state to reflect the changes.
    func test_receive_scrollOffset() {
        let active = ProfileSwitcherItem.fixture()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [active],
            activeAccountId: active.userId,
            allowLockAndLogout: true,
            isVisible: true,
            scrollOffset: .zero
        )

        let newPoint = CGPoint(x: 0, y: 100)
        subject.receive(.profileSwitcher(.scrollOffsetChanged(newPoint)))

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(subject.state.profileSwitcherState.scrollOffset, newPoint)
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    func test_receive_toastShown() {
        let toast = Toast(text: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }
} // swiftlint:disable:this file_length
