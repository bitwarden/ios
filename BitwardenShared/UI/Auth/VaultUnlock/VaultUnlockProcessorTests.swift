import XCTest

@testable import BitwardenShared

class VaultUnlockProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<AuthRoute>!
    var subject: VaultUnlockProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        coordinator = MockCoordinator()

        subject = VaultUnlockProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(authRepository: authRepository),
            state: VaultUnlockState(account: .fixture())
        )
    }

    override func tearDown() {
        super.tearDown()

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
        await subject.perform(.appeared)

        XCTAssertEqual([], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertEqual(profile, subject.state.profileSwitcherState.activeAccountProfile)
        XCTAssertTrue(subject.state.profileSwitcherState.showsAddAccount)
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
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.invalidMasterPassword
            )
        )
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

        try await optionsAlert.tapAction(title: Localizations.logOut)

        let logoutConfirmationAlert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(logoutConfirmationAlert.title, Localizations.logOut)
        XCTAssertEqual(logoutConfirmationAlert.message, Localizations.logoutConfirmation)
        XCTAssertEqual(logoutConfirmationAlert.preferredStyle, .alert)
        XCTAssertEqual(logoutConfirmationAlert.alertActions.count, 2)
        XCTAssertEqual(logoutConfirmationAlert.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(logoutConfirmationAlert.alertActions[1].title, Localizations.cancel)

        try await logoutConfirmationAlert.tapAction(title: Localizations.yes)

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
} // swiftlint:disable:this file_length
