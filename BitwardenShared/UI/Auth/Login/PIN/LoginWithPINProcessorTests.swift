import XCTest

@testable import BitwardenShared

class LoginWithPINProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<AuthRoute>!
    var errorReporter: MockErrorReporter!
    var subject: LoginWithPINProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        coordinator = MockCoordinator<AuthRoute>()
        errorReporter = MockErrorReporter()
        let services = ServiceContainer.withMocks(
            authRepository: authRepository,
            errorReporter: errorReporter
        )
        subject = LoginWithPINProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: LoginWithPINState()
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(.appeared)` with an active account should yield a profile switcher state.
    func test_perform_appeared_activeAccount() async {
        let profile = ProfileSwitcherItem()
        authRepository.accountsResult = .success([profile])
        authRepository.activeAccountResult = .success(profile)
        await subject.perform(.appeared)

        XCTAssertEqual([], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertEqual(profile, subject.state.profileSwitcherState.activeAccountProfile)
        XCTAssertTrue(subject.state.profileSwitcherState.showsAddAccount)
    }

    /// Performing `.logout` logs the user out.
    func test_perform_logout() async throws {
        await subject.perform(.logout)
        let alert = try XCTUnwrap(coordinator.alertShown.first)
        try await alert.tapAction(title: Localizations.yes)
        XCTAssertTrue(authRepository.logoutCalled)
    }

    /// Performing `.unlockWithPIN` unlocks the user's vault and navigates to the vault list view.
    func test_perform_unlockWithPIN() async throws {
        subject.state.pinCode = "123"
        authRepository.unlockWithPINResult = .success(())
        await subject.perform(.unlockWithPIN)
        XCTAssertEqual(coordinator.routes.last, .complete)
    }

    /// Performing `.unlockWithPIN` with the wrong PIN shows an alert.
    func test_perform_unlockWithPIN_invalidPIN() async throws {
        subject.state.pinCode = "123"
        struct VaultUnlockError: Error {}
        authRepository.unlockWithPINResult = .failure(VaultUnlockError())

        await subject.perform(.unlockWithPIN)
        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.invalidPIN
            )
        )
    }

    /// Performing `.unlockWithPIN` with an empty PIN shows an alert.
    func test_perform_unlockWithPIN_validationError() async throws {
        subject.state.pinCode = ""
        await subject.perform(.unlockWithPIN)
        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.validationFieldRequired(Localizations.pin),
                alertActions: [AlertAction(title: Localizations.ok, style: .default)]
            )
        )
    }

    /// Receiving `.pinChanged(_:)` updates the PIN value in the state.
    func test_receive_pinChanged() {
        subject.receive(.pinChanged("123"))
        XCTAssertEqual(subject.state.pinCode, "123")
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

    /// `receive(_:)` with `.profileSwitcherAction(.accountPressed)` updates the state to reflect the changes.
    func test_receive_accountPressed_alternateUnlocked() {
        let profile = ProfileSwitcherItem()
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
        XCTAssertEqual(
            coordinator.routes,
            [.switchAccount(userId: profile.userId)]
        )
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
        XCTAssertEqual(
            coordinator.routes,
            [.switchAccount(userId: profile.userId)]
        )
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
        XCTAssertEqual(
            coordinator.routes,
            [.switchAccount(userId: profile.userId)]
        )
    }

    /// Receiving `.profileSwitcherAction(.addAccountPressed)` navigates to the landing view.
    func test_receive_accountPressed_addAccount() {
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

        subject.receive(.profileSwitcherAction(.addAccountPressed))
        XCTAssertEqual(coordinator.routes.last, .landing)
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

    /// Receiving `.showPIN(_:)` updates the visibility of the PIN in the state.
    func test_receive_showPIN() {
        XCTAssertFalse(subject.state.isPINVisible)
        subject.receive(.showPIN(true))
        XCTAssertTrue(subject.state.isPINVisible)
    }
}
