import XCTest

@testable import BitwardenShared

// MARK: - LandingProcessorTests

class LandingProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<AuthRoute>!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var subject: LandingProcessor!
    var stateService: MockStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        authRepository = MockAuthRepository()
        coordinator = MockCoordinator<AuthRoute>()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()

        let state = LandingState()
        let services = ServiceContainer.withMocks(
            appSettingsStore: appSettingsStore,
            authRepository: authRepository,
            environmentService: environmentService,
            errorReporter: errorReporter,
            stateService: stateService
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
        environmentService = nil
        errorReporter = nil
        subject = nil
        stateService = nil
    }

    // MARK: Tests

    /// `didSaveEnvironment(urls:)` with URLs sets the region to self-hosted and sets the URLs in
    /// the environment.
    func test_didSaveEnvironment() async {
        subject.state.region = .unitedStates
        await subject.didSaveEnvironment(urls: EnvironmentUrlData(base: .example))
        XCTAssertEqual(subject.state.region, .selfHosted)
        XCTAssertEqual(
            environmentService.setPreAuthEnvironmentUrlsData,
            EnvironmentUrlData(base: .example)
        )
    }

    /// `didSaveEnvironment(urls:)` with empty URLs doesn't change the region or the environment URLs.
    func test_didSaveEnvironment_empty() async {
        subject.state.region = .unitedStates
        await subject.didSaveEnvironment(urls: EnvironmentUrlData())
        XCTAssertEqual(subject.state.region, .unitedStates)
        XCTAssertNil(environmentService.setPreAuthEnvironmentUrlsData)
    }

    /// `perform(.appeared)` with no pre-auth URLs defaults the region and URLs to the US environment.
    func test_perform_appeared_loadsRegion_noPreAuthUrls() async {
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .unitedStates)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentUrlsData, .defaultUS)
    }

    /// `perform(.appeared)` with EU pre-auth URLs sets the state to the EU region and sets the
    /// environment URLs.
    func test_perform_appeared_loadsRegion_withPreAuthUrls_europe() async {
        stateService.preAuthEnvironmentUrls = .defaultEU
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .europe)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentUrlsData, .defaultEU)
    }

    /// `perform(.appeared)` with self-hosted pre-auth URLs sets the state to the self-hosted region
    /// and sets the URLs to the environment.
    func test_perform_appeared_loadsRegion_withPreAuthUrls_selfHosted() async {
        let urls = EnvironmentUrlData(base: .example)
        stateService.preAuthEnvironmentUrls = urls
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .selfHosted)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentUrlsData, urls)
    }

    /// `perform(.appeared)` with US pre-auth URLs sets the state to the US region and sets the
    /// environment URLs.
    func test_perform_appeared_loadsRegion_withPreAuthUrls_unitedStates() async {
        stateService.preAuthEnvironmentUrls = .defaultUS
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .unitedStates)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentUrlsData, .defaultUS)
    }

    /// `perform(.appeared)` with an active account and accounts should yield a profile switcher state.
    func test_perform_appeared_profiles_single_active() async {
        let profile = ProfileSwitcherItem()
        authRepository.accountsResult = .success([profile])
        authRepository.activeAccountResult = .success(profile)
        await subject.perform(.appeared)

        XCTAssertEqual([], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertEqual(profile, subject.state.profileSwitcherState.activeAccountProfile)
        XCTAssertFalse(subject.state.profileSwitcherState.showsAddAccount)
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
            ProfileSwitcherState.empty(shouldAlwaysHideAddAccount: true)
        )
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
        authRepository.accountsResult = .success([profile])
        authRepository.activeAccountResult = .success(profile)
        await subject.perform(.appeared)

        XCTAssertEqual([], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertEqual(profile, subject.state.profileSwitcherState.activeAccountProfile)
        XCTAssertFalse(subject.state.profileSwitcherState.showsAddAccount)
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
        authRepository.accountsResult = .success([profile, alternate])
        authRepository.activeAccountResult = .success(profile)
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
    /// log out of the selected account.
    func test_receive_accountLongPressed_logout() async throws {
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

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    func test_receive_toastShown() {
        let toast = Toast(text: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }
} // swiftlint:disable:this file_length
