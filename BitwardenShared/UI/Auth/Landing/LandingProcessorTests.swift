import XCTest

@testable import BitwardenShared

// MARK: - LandingProcessorTests

class LandingProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<AuthRoute>!
    var subject: LandingProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        appSettingsStore = MockAppSettingsStore()
        authRepository = MockAuthRepository()
        coordinator = MockCoordinator<AuthRoute>()

        let state = LandingState()
        let services = ServiceContainer.withMocks(
            appSettingsStore: appSettingsStore,
            authRepository: authRepository
        )
        subject = LandingProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: state
        )
    }

    override func tearDown() {
        super.tearDown()
        authRepository = nil
        appSettingsStore = nil
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(.appeared)` with an active account and accounts should yield a profile switcher state.
    func test_perform_appeared_profiles_single_active() async {
        let profile = ProfileSwitcherItem()
        let state = ProfileSwitcherState(
            accounts: [profile],
            activeAccountId: profile.userId,
            isVisible: false
        )
        authRepository.profileStateResult = .success(state)
        await subject.perform(.appeared)

        XCTAssertEqual([], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertEqual(profile, subject.state.profileSwitcherState.activeAccountProfile)
        XCTAssertFalse(subject.state.profileSwitcherState.showsAddAccount)
    }

    /// `perform(.appeared)` without profiles for the profile switcher.
    func test_perform_appeared_empty() async {
        await subject.perform(.appeared)

        XCTAssertEqual(
            subject.state.profileSwitcherState,
            ProfileSwitcherState.empty(shouldAlwaysHideAddAccount: true)
        )
    }

    /// `perform(.appeared)` with an active account and accounts should yield a profile switcher state.
    func test_perform_appeared_single_active() async {
        let profile = ProfileSwitcherItem()
        let state = ProfileSwitcherState(
            accounts: [profile],
            activeAccountId: profile.userId,
            isVisible: false
        )
        authRepository.profileStateResult = .success(state)
        await subject.perform(.appeared)

        XCTAssertEqual([], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertEqual(profile, subject.state.profileSwitcherState.activeAccountProfile)
        XCTAssertFalse(subject.state.profileSwitcherState.showsAddAccount)
    }

    /// `perform(.appeared)`
    /// No active account and accounts should yield a profile switcher state without an active account.
    func test_perform_refresh_profiles_single_notActive() async {
        let profile = ProfileSwitcherItem()
        let state = ProfileSwitcherState(
            accounts: [profile],
            activeAccountId: nil,
            isVisible: false
        )
        authRepository.profileStateResult = .success(state)
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

    /// `perform(.appeared)`:
    ///  An active account and multiple accounts should yield a profile switcher state.
    func test_perform_refresh_profiles_single_multiAccount() async {
        let profile = ProfileSwitcherItem()
        let alternate = ProfileSwitcherItem()
        let state = ProfileSwitcherState(
            accounts: [profile, alternate],
            activeAccountId: profile.userId,
            isVisible: false
        )
        authRepository.profileStateResult = .success(state)
        await subject.perform(.appeared)

        XCTAssertEqual([alternate], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertEqual(profile, subject.state.profileSwitcherState.activeAccountProfile)
        XCTAssertFalse(subject.state.profileSwitcherState.showsAddAccount)
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

    /// `init` without a remembered email in the app settings store initializes the state correctly.
    func test_init_withoutRememberedEmail() {
        appSettingsStore.rememberedEmail = nil
        let services = ServiceContainer.withMocks(
            appSettingsStore: appSettingsStore
        )
        subject = LandingProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: LandingState()
        )

        XCTAssertEqual(subject.state.email, "")
        XCTAssertFalse(subject.state.isRememberMeOn)
    }

    /// `init` with a remembered email in the app settings store initializes the state correctly.
    func test_init_withRememberedEmail() {
        appSettingsStore.rememberedEmail = "email@example.com"
        let services = ServiceContainer.withMocks(
            appSettingsStore: appSettingsStore
        )
        subject = LandingProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: LandingState()
        )

        XCTAssertEqual(subject.state.email, "email@example.com")
        XCTAssertTrue(subject.state.isRememberMeOn)
    }

    /// `receive(_:)` with `.continuePressed` and an invalid email navigates to the `.alert` route.
    func test_receive_continuePressed_withInvalidEmail() {
        appSettingsStore.rememberedEmail = nil
        subject.state.email = "email"

        subject.receive(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .alert(Alert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.invalidEmail,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ]
        )))
        XCTAssertNil(appSettingsStore.rememberedEmail)
    }

    /// `receive(_:)` with `.continuePressed` and a valid email navigates to the login screen.
    func test_receive_continuePressed_withValidEmail_isRememberMeOn_false() {
        appSettingsStore.rememberedEmail = nil
        subject.state.isRememberMeOn = false
        subject.state.email = "email@example.com"

        subject.receive(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .login(
            username: "email@example.com",
            region: .unitedStates,
            isLoginWithDeviceVisible: false
        ))
        XCTAssertNil(appSettingsStore.rememberedEmail)
    }

    /// `receive(_:)` with `.continuePressed` and a valid email surrounded by whitespace trims the whitespace and
    /// navigates to the login screen.
    func test_receive_continuePressed_withValidEmailAndSpace() {
        subject.state.email = " email@example.com "

        subject.receive(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .login(
            username: "email@example.com",
            region: .unitedStates,
            isLoginWithDeviceVisible: false
        ))
    }

    /// `receive(_:)` with `.continuePressed` and a valid email with uppercase characters converts the email to
    /// lowercase and navigates to the login screen.
    func test_receive_continuePressed_withValidEmailUppercased() {
        subject.state.email = "EMAIL@EXAMPLE.COM"

        subject.receive(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .login(
            username: "email@example.com",
            region: .unitedStates,
            isLoginWithDeviceVisible: false
        ))
    }

    /// `receive(_:)` with `.continuePressed` and a valid email navigates to the login screen.
    func test_receive_continuePressed_withValidEmail_isRememberMeOn_true() {
        appSettingsStore.rememberedEmail = nil
        subject.state.isRememberMeOn = true
        subject.state.email = "email@example.com"

        subject.receive(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .login(
            username: "email@example.com",
            region: .unitedStates,
            isLoginWithDeviceVisible: false
        ))
        XCTAssertEqual(appSettingsStore.rememberedEmail, "email@example.com")
    }

    /// `receive(_:)` with `.createAccountPressed` navigates to the create account screen.
    func test_receive_createAccountPressed() {
        subject.receive(.createAccountPressed)
        XCTAssertEqual(coordinator.routes.last, .createAccount)
    }

    /// `receive(_:)` with `.emailChanged` and an empty value updates the state to reflect the changes.
    func test_receive_emailChanged_empty() {
        subject.state.email = "email@example.com"

        subject.receive(.emailChanged(""))
        XCTAssertEqual(subject.state.email, "")
        XCTAssertFalse(subject.state.isContinueButtonEnabled)
    }

    /// `receive(_:)` with `.emailChanged` and an email value updates the state to reflect the changes.
    func test_receive_emailChanged_value() {
        XCTAssertEqual(subject.state.email, "")

        subject.receive(.emailChanged("email@example.com"))
        XCTAssertEqual(subject.state.email, "email@example.com")
        XCTAssertTrue(subject.state.isContinueButtonEnabled)
    }

    /// `receive(_:)` with `.regionPressed` navigates to the region selection screen.
    func test_receive_regionPressed() async throws {
        subject.receive(.regionPressed)

        let route = coordinator.routes.last
        guard let route, case let AuthRoute.alert(alert) = route
        else {
            XCTFail("The last route was not an `.alert`: \(String(describing: route))")
            return
        }
        XCTAssertEqual(alert.title, Localizations.loggingInOn)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions.count, 4)

        XCTAssertEqual(alert.alertActions[0].title, "bitwarden.com")
        try await alert.tapAction(title: "bitwarden.com")
        XCTAssertEqual(subject.state.region, .unitedStates)

        XCTAssertEqual(alert.alertActions[1].title, "bitwarden.eu")
        try await alert.tapAction(title: "bitwarden.eu")
        XCTAssertEqual(subject.state.region, .europe)

        XCTAssertEqual(alert.alertActions[2].title, Localizations.selfHosted)
        try await alert.tapAction(title: Localizations.selfHosted)
        XCTAssertEqual(subject.state.region, .selfHosted)
        XCTAssertEqual(coordinator.routes.last, .selfHosted)
    }

    /// `receive(_:)` with `.rememberMeChanged(true)` updates the state to reflect the changes.
    func test_receive_rememberMeChanged_true() {
        XCTAssertFalse(subject.state.isRememberMeOn)

        subject.receive(.rememberMeChanged(true))
        XCTAssertTrue(subject.state.isRememberMeOn)
    }

    /// `receive(_:)` with `.rememberMeChanged(false)` updates the state to reflect the changes.
    func test_receive_rememberMeChanged_false() {
        appSettingsStore.rememberedEmail = "email@example.com"
        subject.state.isRememberMeOn = true

        subject.receive(.rememberMeChanged(false))
        XCTAssertFalse(subject.state.isRememberMeOn)
        XCTAssertNil(appSettingsStore.rememberedEmail)
    }

    /// `receive(_:)` with `.profileSwitcherAction(.accountPressed)` updates the state to reflect the changes.
    func test_receive_accountPressed_active_unlocked() {
        let profile = ProfileSwitcherItem()
        let state = ProfileSwitcherState(
            accounts: [profile],
            activeAccountId: profile.userId,
            isVisible: true
        )
        authRepository.profileStateResult = .success(state)
        subject.state.profileSwitcherState = state

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
    func test_receive_accountPressed_active_locked() {
        let profile = ProfileSwitcherItem(isUnlocked: false)
        let account = Account.fixture(profile: .fixture(
            userId: profile.userId
        ))
        let state = ProfileSwitcherState(
            accounts: [profile],
            activeAccountId: profile.userId,
            isVisible: true
        )
        authRepository.profileStateResult = .success(state)
        authRepository.accountResult = .success(account)
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
        XCTAssertEqual(
            coordinator.routes,
            [.switchAccount(userId: profile.userId)]
        )
    }

    /// `receive(_:)` with `.profileSwitcherAction(.accountPressed)` updates the state to reflect the changes.
    func test_receive_accountPressed_alternateUnlocked() {
        let profile = ProfileSwitcherItem()
        let active = ProfileSwitcherItem()
        let account = Account.fixture(profile: .fixture(
            userId: profile.userId
        ))
        let state = ProfileSwitcherState(
            accounts: [profile, active],
            activeAccountId: active.userId,
            isVisible: true
        )
        authRepository.profileStateResult = .success(state)
        authRepository.accountResult = .success(account)
        subject.state.profileSwitcherState = state

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
        let state = ProfileSwitcherState(
            accounts: [profile, active],
            activeAccountId: active.userId,
            isVisible: true
        )
        authRepository.profileStateResult = .success(state)
        authRepository.accountResult = .success(account)
        subject.state.profileSwitcherState = state

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
        let state = ProfileSwitcherState(
            accounts: [active],
            activeAccountId: active.userId,
            isVisible: false
        )
        authRepository.profileStateResult = .success(state)
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
        waitFor(!subject.state.profileSwitcherState.isVisible)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(coordinator.routes, [])
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
} // swiftlint:disable:this file_length
