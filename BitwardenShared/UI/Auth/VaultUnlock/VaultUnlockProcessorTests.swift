import XCTest

@testable import BitwardenShared

class VaultUnlockProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appExtensionDelegate: MockAppExtensionDelegate!
    var authRepository: MockAuthRepository!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var coordinator: MockCoordinator<AuthRoute>!
    var subject: VaultUnlockProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockAppExtensionDelegate()
        authRepository = MockAuthRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()

        subject = VaultUnlockProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
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
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(.appeared)` with an active account and accounts should yield a profile switcher state.
    func test_perform_appeared_profiles_single_active() async {
        let profile = ProfileSwitcherItem()
        authRepository.accountsResult = .success([profile])
        authRepository.activeAccountResult = .success(profile)
        stateService.activeAccount = .fixture()
        await stateService.setUnsuccessfulUnlockAttempts(3)
        await subject.perform(.appeared)

        XCTAssertEqual([], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertEqual(profile, subject.state.profileSwitcherState.activeAccountProfile)
        XCTAssertTrue(subject.state.profileSwitcherState.showsAddAccount)
        XCTAssertEqual(3, subject.state.unsuccessfulUnlockAttemptsCount)
    }

    /// `perform(.appeared)`
    ///  Mismatched active account and accounts should yield an empty profile switcher state.
    func test_perform_appeared_mismatch() async {
        let profile = ProfileSwitcherItem()
        authRepository.accountsResult = .success([])
        authRepository.activeAccountResult = .success(profile)
        await subject.perform(.appeared)

        XCTAssertEqual(
            subject.state.profileSwitcherState,
            ProfileSwitcherState.empty()
        )
    }

    /// `perform(.appeared)` without profiles for the profile switcher.
    func test_perform_appeared_empty() async {
        await subject.perform(.appeared)

        XCTAssertEqual(
            subject.state.profileSwitcherState,
            ProfileSwitcherState.empty()
        )
    }

    /// `perform(.appeared)` refreshes the profile switcher and disables add account when running
    /// in the app extension.
    func test_perform_appeared_refreshProfile_inAppExtension() async {
        let profile = ProfileSwitcherItem()
        authRepository.accountsResult = .success([profile])
        appExtensionDelegate.isInAppExtension = true

        await subject.perform(.appeared)

        XCTAssertEqual(
            subject.state.profileSwitcherState,
            ProfileSwitcherState(
                accounts: [profile],
                activeAccountId: nil,
                isVisible: false,
                shouldAlwaysHideAddAccount: true
            )
        )
    }

    /// `perform(.appeared)` with an active account and accounts should yield a profile switcher state.
    func test_perform_appeared_single_active() async {
        let profile = ProfileSwitcherItem()
        authRepository.accountsResult = .success([profile])
        authRepository.activeAccountResult = .success(profile)
        await subject.perform(.appeared)

        XCTAssertEqual([], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertEqual(profile, subject.state.profileSwitcherState.activeAccountProfile)
        XCTAssertTrue(subject.state.profileSwitcherState.showsAddAccount)
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

    /// `perform(.appeared)`
    /// No active account and accounts should yield a profile switcher state without an active account.
    func test_perform_refresh_profiles_single_notActive() async {
        let profile = ProfileSwitcherItem()
        authRepository.accountsResult = .success([profile])
        await subject.perform(.appeared)

        XCTAssertEqual(
            subject.state.profileSwitcherState,
            ProfileSwitcherState(
                accounts: [profile],
                activeAccountId: nil,
                isVisible: false
            )
        )
    }

    /// `perform(.appeared)`:
    ///  An active account and multiple accounts should yield a profile switcher state.
    func test_perform_refresh_profiles_single_multiAccount() async {
        let profile = ProfileSwitcherItem()
        let alternate = ProfileSwitcherItem()
        authRepository.accountsResult = .success([profile, alternate])
        authRepository.activeAccountResult = .success(profile)
        await subject.perform(.appeared)

        XCTAssertEqual([alternate], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertEqual(profile, subject.state.profileSwitcherState.activeAccountProfile)
        XCTAssertTrue(subject.state.profileSwitcherState.showsAddAccount)
    }

    /// `perform(.profileSwitcher(.rowAppeared))` should not update the state for add Account
    func test_perform_rowAppeared_add() async {
        let profile = ProfileSwitcherItem()
        let alternate = ProfileSwitcherItem()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, alternate],
            activeAccountId: profile.userId,
            isVisible: true
        )

        await subject.perform(.profileSwitcher(.rowAppeared(.addAccount)))

        XCTAssertFalse(subject.state.profileSwitcherState.hasSetAccessibilityFocus)
    }

    /// `perform(.profileSwitcher(.rowAppeared))` should not update the state for alternate account
    func test_perform_rowAppeared_alternate() async {
        let profile = ProfileSwitcherItem()
        let alternate = ProfileSwitcherItem()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, alternate],
            activeAccountId: profile.userId,
            isVisible: true
        )

        await subject.perform(.profileSwitcher(.rowAppeared(.alternate(alternate))))

        XCTAssertFalse(subject.state.profileSwitcherState.hasSetAccessibilityFocus)
    }

    /// `perform(.profileSwitcher(.rowAppeared))` should update the state for active account
    func test_perform_rowAppeared_active() {
        let profile = ProfileSwitcherItem()
        let alternate = ProfileSwitcherItem()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, alternate],
            activeAccountId: profile.userId,
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
        subject.state.masterPassword = "password"

        await subject.perform(.unlockVault)

        XCTAssertEqual(authRepository.unlockVaultPassword, "password")
        XCTAssertEqual(coordinator.routes.last, .complete)
    }

    /// `perform(_:)` with `.unlockVault` shows an alert if the master password is empty.
    func test_perform_unlockVault_InputValidationError() async throws {
        await subject.perform(.unlockVault)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(
            alert,
            Alert.inputValidationAlert(error: InputValidationError(
                message: Localizations.validationFieldRequired(Localizations.masterPassword)
            ))
        )
    }

    /// `perform(_:)` with `.unlockVault` shows an alert if the master password was incorrect.
    func test_perform_unlockVault_invalidPasswordError() async throws {
        subject.state.masterPassword = "password"

        struct VaultUnlockError: Error {}
        authRepository.unlockVaultResult = .failure(VaultUnlockError())

        await subject.perform(.unlockVault)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, Localizations.anErrorHasOccurred)
        XCTAssertEqual(alert.message, Localizations.invalidMasterPassword)
    }

    /// `perform(_:)` with `.unlockVault` displays an alert a maximum of 5 times if the master password was incorrect.
    ///  After the 5th attempt, it logs the user out.
    func test_perform_unlockVault_invalidPassword_logout() async throws {
        subject.state.masterPassword = "password"
        stateService.activeAccount = .fixture()
        XCTAssertEqual(subject.state.unsuccessfulUnlockAttemptsCount, 0)
        struct VaultUnlockError: Error {}
        authRepository.unlockVaultResult = .failure(VaultUnlockError())

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
        XCTAssertTrue(authRepository.logoutCalled)
        XCTAssertEqual(coordinator.routes.last, .landing)
    }

    /// `perform(_:)` with `.unlockVault` logs error if force logout fails after the 5th unsuccessful attempts.
    func test_perform_unlockVault_invalidPassword_logoutError() async throws {
        subject.state.masterPassword = "password"
        stateService.activeAccount = .fixture()
        subject.state.unsuccessfulUnlockAttemptsCount = 4
        await stateService.setUnsuccessfulUnlockAttempts(5)
        XCTAssertEqual(subject.state.unsuccessfulUnlockAttemptsCount, 4)
        struct VaultUnlockError: Error {}
        authRepository.unlockVaultResult = .failure(VaultUnlockError())
        struct LogoutError: Error, Equatable {}
        authRepository.logoutResult = .failure(LogoutError())

        // 5th unsuccessful attempts
        await subject.perform(.unlockVault)

        XCTAssertTrue(authRepository.logoutCalled)
        XCTAssertEqual(errorReporter.errors.last as? NSError, BitwardenError.logoutError(error: LogoutError()))
        XCTAssertEqual(coordinator.routes.last, .landing)
    }

    /// `perform(_:)` with `.unlockVault` successful unlocking vault resets the `unsuccessfulUnlockAttemptsCount`.
    func test_perform_unlockVault_validPassword_resetsFailedUnlockAttemptsCount() async throws {
        subject.state.masterPassword = "password"
        XCTAssertEqual(subject.state.unsuccessfulUnlockAttemptsCount, 0)
        struct VaultUnlockError: Error {}
        authRepository.unlockVaultResult = .failure(VaultUnlockError())
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

        authRepository.unlockVaultResult = .success(())
        await subject.perform(.unlockVault)
        XCTAssertEqual(subject.state.unsuccessfulUnlockAttemptsCount, 0)
        attemptsInUserDefaults = await stateService.getUnsuccessfulUnlockAttempts()
        XCTAssertEqual(attemptsInUserDefaults, 0)
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

        XCTAssertTrue(authRepository.logoutCalled)
        XCTAssertEqual(coordinator.routes.last, .landing)
    }

    /// `receive(_:)` with `.revealMasterPasswordFieldPressed` updates the state to reflect the changes.
    func test_receive_revealMasterPasswordFieldPressed() {
        subject.state.isMasterPasswordRevealed = false
        subject.receive(.revealMasterPasswordFieldPressed(true))
        XCTAssertTrue(subject.state.isMasterPasswordRevealed)

        subject.receive(.revealMasterPasswordFieldPressed(false))
        XCTAssertFalse(subject.state.isMasterPasswordRevealed)
    }

    /// `receive(_:)` with `.profileSwitcherAction(.accountLongPressed)` shows the alert and allows the user to
    /// lock the selected account.
    func test_receive_accountLongPressed_lock() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem()
        let otherProfile = ProfileSwitcherItem(isUnlocked: true, userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            isVisible: true
        )
        authRepository.activeAccountResult = .success(activeProfile)

        subject.receive(.profileSwitcherAction(.accountLongPressed(otherProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to lock the account.
        let lockAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await lockAction.handler?(lockAction, [])

        // Verify the results.
        XCTAssertEqual(authRepository.lockVaultUserId, otherProfile.userId)
        XCTAssertEqual(subject.state.toast?.text, Localizations.accountLockedSuccessfully)
    }

    /// `receive(_:)` with `.profileSwitcherAction(.accountLongPressed)` records any errors from locking the account.
    func test_receive_accountLongPressed_lock_error() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem()
        let otherProfile = ProfileSwitcherItem(isUnlocked: true, userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            isVisible: true
        )
        authRepository.activeAccountResult = .failure(BitwardenTestError.example)

        subject.receive(.profileSwitcherAction(.accountLongPressed(otherProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to lock the account.
        let lockAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await lockAction.handler?(lockAction, [])

        // Verify the results.
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `receive(_:)` with `.profileSwitcherAction(.accountLongPressed)` shows the alert and allows the user to
    /// log out of the selected account, which navigates back to the landing page for the active account.
    func test_receive_accountLongPressed_logout_activeAccount() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem()
        let otherProfile = ProfileSwitcherItem(userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            isVisible: true
        )
        authRepository.activeAccountResult = .success(activeProfile)

        subject.receive(.profileSwitcherAction(.accountLongPressed(activeProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to log out from the account.
        let logoutAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await logoutAction.handler?(logoutAction, [])

        // Confirm logging out on the second alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Verify the results.
        XCTAssertEqual(authRepository.logoutUserId, activeProfile.userId)
        XCTAssertEqual(coordinator.routes.last, .landing)
    }

    /// `receive(_:)` with `.profileSwitcherAction(.accountLongPressed)` shows the alert and allows the user to
    /// log out of the selected account, which displays a toast.
    func test_receive_accountLongPressed_logout_otherAccount() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem()
        let otherProfile = ProfileSwitcherItem(userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            isVisible: true
        )
        authRepository.activeAccountResult = .success(activeProfile)

        subject.receive(.profileSwitcherAction(.accountLongPressed(otherProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to log out from the account.
        let logoutAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await logoutAction.handler?(logoutAction, [])

        // Confirm logging out on the second alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Verify the results.
        XCTAssertEqual(authRepository.logoutUserId, otherProfile.userId)
        XCTAssertEqual(subject.state.toast?.text, Localizations.accountLoggedOutSuccessfully)
    }

    /// `receive(_:)` with `.profileSwitcherAction(.accountLongPressed)` records any errors from logging out the
    /// account.
    func test_receive_accountLongPressed_logout_error() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem()
        let otherProfile = ProfileSwitcherItem(userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            isVisible: true
        )
        authRepository.activeAccountResult = .failure(BitwardenTestError.example)

        subject.receive(.profileSwitcherAction(.accountLongPressed(otherProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to log out from the account.
        let logoutAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await logoutAction.handler?(logoutAction, [])

        // Confirm logging out on the second alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Verify the results.
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `receive(_:)` with `.profileSwitcherAction(.accountPressed)` updates the state to reflect the changes.
    func test_receive_accountPressed_active_unlocked() {
        let profile = ProfileSwitcherItem()
        authRepository.accountsResult = .success([profile])
        authRepository.activeAccountResult = .success(profile)
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile],
            activeAccountId: profile.userId,
            isVisible: true
        )

        let task = Task {
            subject.receive(.profileSwitcherAction(.accountPressed(profile)))
        }
        waitFor(!subject.state.profileSwitcherState.isVisible)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(coordinator.routes, [.switchAccount(userId: profile.userId)])
    }

    /// `receive(_:)` with `.profileSwitcherAction(.accountPressed)` updates the state to reflect the changes.
    func test_receive_accountPressed_active_locked() {
        let profile = ProfileSwitcherItem(isUnlocked: false)
        let account = Account.fixture(profile: .fixture(
            userId: profile.userId
        ))
        authRepository.accountsResult = .success([profile])
        authRepository.activeAccountResult = .success(profile)
        authRepository.accountForItemResult = .success(account)
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile],
            activeAccountId: profile.userId,
            isVisible: true
        )

        let task = Task {
            subject.receive(.profileSwitcherAction(.accountPressed(profile)))
        }
        waitFor(!subject.state.profileSwitcherState.isVisible)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(coordinator.routes, [.switchAccount(userId: profile.userId)])
    }

    /// `receive(_:)` with `.profileSwitcherAction(.accountPressed)` updates the state to reflect the changes.
    func test_receive_accountPressed_alternateUnlocked() {
        let profile = ProfileSwitcherItem(isUnlocked: true)
        let active = ProfileSwitcherItem()
        let account = Account.fixture(profile: .fixture(
            userId: profile.userId
        ))
        authRepository.accountsResult = .success([active, profile])
        authRepository.accountForItemResult = .success(account)
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, active],
            activeAccountId: active.userId,
            isVisible: true
        )

        let task = Task {
            subject.receive(.profileSwitcherAction(.accountPressed(profile)))
        }
        waitFor(!subject.state.profileSwitcherState.isVisible)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(coordinator.routes, [.switchAccount(userId: profile.userId)])
    }

    /// `receive(_:)` with `.profileSwitcherAction(.accountPressed)` updates the state to reflect the changes.
    func test_receive_accountPressed_alternateLocked() {
        let profile = ProfileSwitcherItem(isUnlocked: false)
        let active = ProfileSwitcherItem()
        let account = Account.fixture(profile: .fixture(
            userId: profile.userId
        ))
        authRepository.accountsResult = .success([active, profile])
        authRepository.accountForItemResult = .success(account)
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, active],
            activeAccountId: active.userId,
            isVisible: true
        )

        let task = Task {
            subject.receive(.profileSwitcherAction(.accountPressed(profile)))
        }
        waitFor(!subject.state.profileSwitcherState.isVisible)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(coordinator.routes, [.switchAccount(userId: profile.userId)])
    }

    /// `receive(_:)` with `.profileSwitcherAction(.accountPressed)` updates the state to reflect the changes.
    func test_receive_accountPressed_noMatch() {
        let profile = ProfileSwitcherItem()
        let active = ProfileSwitcherItem()
        authRepository.accountsResult = .success([active])
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, active],
            activeAccountId: active.userId,
            isVisible: true
        )

        let task = Task {
            subject.receive(.profileSwitcherAction(.accountPressed(profile)))
        }
        waitFor(!subject.state.profileSwitcherState.isVisible)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(coordinator.routes, [.switchAccount(userId: profile.userId)])
    }

    /// `receive(_:)` with `.profileSwitcherAction(.addAccountPressed)` updates the state to reflect the changes.
    func test_receive_addAccountPressed() {
        let active = ProfileSwitcherItem()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [active],
            activeAccountId: active.userId,
            isVisible: true
        )

        let task = Task {
            subject.receive(.profileSwitcherAction(.addAccountPressed))
        }
        waitFor(!coordinator.routes.isEmpty)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(coordinator.routes, [.landing])
    }

    /// `receive(_:)` with `.profileSwitcherAction(.backgroundPressed)` updates the state to reflect the changes.
    func test_receive_backgroundPressed() {
        let active = ProfileSwitcherItem()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [active],
            activeAccountId: active.userId,
            isVisible: true
        )

        let task = Task {
            subject.receive(.profileSwitcherAction(.backgroundPressed))
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
        let active = ProfileSwitcherItem()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [active],
            activeAccountId: active.userId,
            isVisible: true
        )

        let task = Task {
            subject.receive(.profileSwitcherAction(.requestedProfileSwitcher(visible: false)))
        }
        waitFor(!subject.state.profileSwitcherState.isVisible)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.requestedProfileSwitcher(visible:)` updates the state to reflect the changes.
    func test_receive_requestedProfileSwitcherVisible_true() {
        let active = ProfileSwitcherItem()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [active],
            activeAccountId: active.userId,
            isVisible: false
        )

        let task = Task {
            subject.receive(.profileSwitcherAction(.requestedProfileSwitcher(visible: true)))
        }
        waitFor(subject.state.profileSwitcherState.isVisible)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.profileSwitcherAction(.scrollOffset)` updates the state to reflect the changes.
    func test_receive_scrollOffset() {
        let active = ProfileSwitcherItem()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [active],
            activeAccountId: active.userId,
            isVisible: true,
            scrollOffset: .zero
        )

        let newPoint = CGPoint(x: 0, y: 100)
        subject.receive(.profileSwitcherAction(.scrollOffsetChanged(newPoint)))

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
