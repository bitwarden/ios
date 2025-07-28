import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenShared

// MARK: - LandingProcessorTests

class LandingProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var authRepository: MockAuthRepository!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var subject: LandingProcessor!
    var stateService: MockStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        authRepository = MockAuthRepository()
        configService = MockConfigService()
        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()

        let state = LandingState()
        let services = ServiceContainer.withMocks(
            appSettingsStore: appSettingsStore,
            authRepository: authRepository,
            configService: configService,
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
        configService = nil
        coordinator = nil
        environmentService = nil
        errorReporter = nil
        subject = nil
        stateService = nil
    }

    // MARK: Tests

    /// `didChangeRegion(urls:)` update URLs when they change on the StartRegistration modal
    @MainActor
    func test_didChangeRegion() async {
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(base: .example)
        subject.state.region = .unitedStates
        await subject.didChangeRegion()
        XCTAssertEqual(subject.state.region, .selfHosted)
        XCTAssertEqual(
            environmentService.setPreAuthEnvironmentURLsData,
            EnvironmentURLData(base: .example)
        )
    }

    /// `didSaveEnvironment(urls:)` with URLs sets the region to self-hosted and sets the URLs in
    /// the environment.
    @MainActor
    func test_didSaveEnvironment() async {
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(base: .example)
        subject.state.region = .unitedStates
        await subject.didSaveEnvironment(urls: EnvironmentURLData(base: .example))
        XCTAssertEqual(subject.state.region, .selfHosted)
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.environmentSaved))
        XCTAssertEqual(
            environmentService.setPreAuthEnvironmentURLsData,
            EnvironmentURLData(base: .example)
        )
    }

    /// `didSaveEnvironment(urls:)` with empty URLs doesn't change the region or the environment URLs.
    @MainActor
    func test_didSaveEnvironment_empty() async {
        stateService.preAuthEnvironmentURLs = EnvironmentURLData()
        subject.state.region = .unitedStates
        await subject.didSaveEnvironment(urls: EnvironmentURLData())
        XCTAssertEqual(subject.state.region, .unitedStates)
        XCTAssertNil(environmentService.setPreAuthEnvironmentURLsData)
    }

    /// `perform(.appeared)` with no pre-auth URLs defaults the region and URLs to the US environment.
    @MainActor
    func test_perform_appeared_loadsRegion_noPreAuthUrls() async {
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .unitedStates)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentURLsData, .defaultUS)
    }

    /// `perform(.appeared)` with EU pre-auth URLs sets the state to the EU region and sets the
    /// environment URLs.
    @MainActor
    func test_perform_appeared_loadsRegion_withPreAuthUrls_europe() async {
        stateService.preAuthEnvironmentURLs = .defaultEU
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .europe)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentURLsData, .defaultEU)
    }

    /// `perform(.appeared)` with self-hosted pre-auth URLs sets the state to the self-hosted region
    /// and sets the URLs to the environment.
    @MainActor
    func test_perform_appeared_loadsRegion_withPreAuthUrls_selfHosted() async {
        let urls = EnvironmentURLData(base: .example)
        stateService.preAuthEnvironmentURLs = urls
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .selfHosted)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentURLsData, urls)
    }

    /// `perform(.appeared)` with US pre-auth URLs sets the state to the US region and sets the
    /// environment URLs.
    @MainActor
    func test_perform_appeared_loadsRegion_withPreAuthUrls_unitedStates() async {
        stateService.preAuthEnvironmentURLs = .defaultUS
        await subject.perform(.appeared)
        XCTAssertEqual(subject.state.region, .unitedStates)
        XCTAssertEqual(environmentService.setPreAuthEnvironmentURLsData, .defaultUS)
    }

    /// `perform(.appeared)` with an active account and accounts should yield a profile switcher state.
    @MainActor
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
        XCTAssertFalse(subject.state.profileSwitcherState.showsAddAccount)
    }

    /// `perform(.appeared)` without profiles for the profile switcher.
    @MainActor
    func test_perform_appeared_empty() async {
        await subject.perform(.appeared)

        XCTAssertEqual(
            subject.state.profileSwitcherState,
            ProfileSwitcherState.empty(shouldAlwaysHideAddAccount: true)
        )
    }

    /// `perform(.appeared)` with an active account and accounts should yield a profile switcher state.
    @MainActor
    func test_perform_appeared_single_active() async {
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
        XCTAssertFalse(subject.state.profileSwitcherState.showsAddAccount)
    }

    /// `perform(_:)` with `.continuePressed` and an invalid email shows an error alert.
    @MainActor
    func test_perform_continuePressed_withInvalidEmail() async {
        appSettingsStore.rememberedEmail = nil
        subject.state.email = "email"

        await subject.perform(.continuePressed)
        XCTAssertEqual(coordinator.alertShown.last, Alert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.invalidEmail,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ]
        ))
        XCTAssertNil(appSettingsStore.rememberedEmail)
    }

    /// `perform(_:)` with `.continuePressed` and a valid email navigates to the login screen.
    @MainActor
    func test_perform_continuePressed_withValidEmail_isRememberMeOn_false() async {
        appSettingsStore.rememberedEmail = nil
        subject.state.isRememberMeOn = false
        subject.state.email = "email@example.com"

        await subject.perform(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .login(username: "email@example.com"))
        XCTAssertNil(appSettingsStore.rememberedEmail)
    }

    /// `perform(_:)` with `.continuePressed` and a valid email surrounded by whitespace trims the whitespace and
    /// navigates to the login screen.
    @MainActor
    func test_perform_continuePressed_withValidEmailAndSpace() async {
        subject.state.email = " email@example.com "

        await subject.perform(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .login(username: "email@example.com"))
    }

    /// `perform(_:)` with `.continuePressed` and a valid email with uppercase characters converts the email to
    /// lowercase and navigates to the login screen.
    @MainActor
    func test_perform_continuePressed_withValidEmailUppercased() async {
        subject.state.email = "EMAIL@EXAMPLE.COM"

        await subject.perform(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .login(username: "email@example.com"))
    }

    /// `perform(_:)` with `.continuePressed` and a valid email navigates to the login screen.
    @MainActor
    func test_perform_continuePressed_withValidEmail_isRememberMeOn_true() async {
        appSettingsStore.rememberedEmail = nil
        subject.state.isRememberMeOn = true
        subject.state.email = "email@example.com"

        await subject.perform(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .login(username: "email@example.com"))
        XCTAssertEqual(appSettingsStore.rememberedEmail, "email@example.com")
    }

    /// `perform(_:)` with `.continuePressed` when the account matches an existing account shows the
    /// user an alert to switch to that account.
    @MainActor
    func test_perform_continuePressed_matchingExistingAccount() async throws {
        appSettingsStore.rememberedEmail = nil
        authRepository.existingAccountUserIdResult = "1"
        subject.state.email = "email@example.com"

        await subject.perform(.continuePressed)

        XCTAssertEqual(authRepository.existingAccountUserIdEmail, "email@example.com")
        XCTAssertEqual(coordinator.alertShown, [.switchToExistingAccount {}])
        let alert = coordinator.alertShown[0]

        try await alert.tapAction(title: Localizations.cancel)
        XCTAssertTrue(coordinator.routes.isEmpty)

        try await alert.tapAction(title: Localizations.yes)
        XCTAssertEqual(coordinator.events, [.action(.switchAccount(isAutomatic: false, userId: "1"))])
        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `perform(.appeared)`
    /// No active account and accounts should yield a profile switcher state without an active account.
    @MainActor
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
                isVisible: false,
                shouldAlwaysHideAddAccount: true,
                showPlaceholderToolbarIcon: true
            )
        )
    }

    /// `perform(.appeared)`:
    ///  An active account and multiple accounts should yield a profile switcher state.
    @MainActor
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
        XCTAssertFalse(subject.state.profileSwitcherState.showsAddAccount)
    }

    /// `perform(.profileSwitcher(.rowAppeared))` should not update the state for add Account
    @MainActor
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
    @MainActor
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
    @MainActor
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

    /// `init` without a remembered email in the app settings store initializes the state correctly.
    @MainActor
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
    @MainActor
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

    /// `receive(_:)` with `.createAccountPressed` navigates to the start registration screen.
    @MainActor
    func test_receive_createAccountPressed() {
        subject.receive(.createAccountPressed)
        XCTAssertEqual(coordinator.routes.last, .startRegistration)
    }

    /// `receive(_:)` with `.emailChanged` and an empty value updates the state to reflect the changes.
    @MainActor
    func test_receive_emailChanged_empty() {
        subject.state.email = "email@example.com"

        subject.receive(.emailChanged(""))
        XCTAssertEqual(subject.state.email, "")
        XCTAssertFalse(subject.state.isContinueButtonEnabled)
    }

    /// `receive(_:)` with `.emailChanged` and an email value updates the state to reflect the changes.
    @MainActor
    func test_receive_emailChanged_value() {
        XCTAssertEqual(subject.state.email, "")

        subject.receive(.emailChanged("email@example.com"))
        XCTAssertEqual(subject.state.email, "email@example.com")
        XCTAssertTrue(subject.state.isContinueButtonEnabled)
    }

    /// `perform(_:)` with `.regionPressed` navigates to the region selection screen.
    @MainActor
    func test_perform_regionPressed() async throws {
        await subject.perform(.regionPressed)

        var alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, Localizations.loggingInOn)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions.count, 4)

        XCTAssertEqual(alert.alertActions[0].title, "bitwarden.com")
        try await alert.tapAction(title: "bitwarden.com")
        XCTAssertEqual(subject.state.region, .unitedStates)

        await subject.perform(.regionPressed)
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.alertActions[1].title, "bitwarden.eu")
        try await alert.tapAction(title: "bitwarden.eu")
        XCTAssertEqual(subject.state.region, .europe)

        await subject.perform(.regionPressed)
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.selfHosted)
        try await alert.tapAction(title: Localizations.selfHosted)
        XCTAssertEqual(coordinator.routes.last, .selfHosted(currentRegion: .europe))
    }

    /// `receive(_:)` with `.rememberMeChanged(true)` updates the state to reflect the changes.
    @MainActor
    func test_receive_rememberMeChanged_true() {
        XCTAssertFalse(subject.state.isRememberMeOn)

        subject.receive(.rememberMeChanged(true))
        XCTAssertTrue(subject.state.isRememberMeOn)
    }

    /// `receive(_:)` with `.rememberMeChanged(false)` updates the state to reflect the changes.
    @MainActor
    func test_receive_rememberMeChanged_false() {
        appSettingsStore.rememberedEmail = "email@example.com"
        subject.state.isRememberMeOn = true

        subject.receive(.rememberMeChanged(false))
        XCTAssertFalse(subject.state.isRememberMeOn)
        XCTAssertNil(appSettingsStore.rememberedEmail)
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` shows the alert and allows the user to
    /// lock the selected account.
    @MainActor
    func test_receive_accountLongPressed_lock() async throws {
        // Set up the mock data.
        let activeProfile = ProfileSwitcherItem.fixture()
        let otherProfile = ProfileSwitcherItem.fixture(isUnlocked: true, userId: "42")
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [otherProfile, activeProfile],
            activeAccountId: activeProfile.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        authRepository.activeAccount = .fixture()

        await subject.perform(.profileSwitcher(.accountLongPressed(otherProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to lock the account.
        let lockAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await lockAction.handler?(lockAction, [])

        // Verify the results.
        XCTAssertEqual(
            coordinator.events.last,
            .action(.lockVault(userId: otherProfile.userId, isManuallyLocking: true))
        )
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.accountLockedSuccessfully))
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` records any errors from locking the account.
    @MainActor
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
    /// log out of the selected account.
    @MainActor
    func test_receive_accountLongPressed_logout() async throws {
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

        await subject.perform(.profileSwitcher(.accountLongPressed(otherProfile)))
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)

        // Select the alert action to log out from the account.
        let logoutAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await logoutAction.handler?(logoutAction, [])

        // Confirm logging out on the second alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Verify the results.
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.accountLoggedOutSuccessfully))
        XCTAssertEqual(
            coordinator.events.last,
            .action(.logout(userId: otherProfile.userId, userInitiated: true))
        )
    }

    /// `receive(_:)` with `.profileSwitcher(.accountLongPressed)` records any errors from logging out the
    /// account.
    @MainActor
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

    /// `receive(_:)` with `.profileSwitcher(.accountPressed)` with the active account
    ///  dismisses the profile switcher.
    @MainActor
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
        XCTAssertEqual(
            coordinator.events,
            [
                .action(.switchAccount(isAutomatic: false, userId: profile.userId)),
            ]
        )
    }

    /// `receive(_:)` with `.profileSwitcher(.accountPressed)`  with the active account
    ///  dismisses the profile switcher.
    @MainActor
    func test_receive_accountPressed_active_locked() {
        let profile = ProfileSwitcherItem.fixture(isUnlocked: false)
        let account = Account.fixture(profile: .fixture(
            userId: profile.userId
        ))
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile],
            activeAccountId: profile.userId,
            allowLockAndLogout: true,
            isVisible: true
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
        XCTAssertEqual(
            coordinator.events,
            [
                .action(.switchAccount(isAutomatic: false, userId: profile.userId)),
            ]
        )
    }

    /// `receive(_:)` with `.profileSwitcher(.accountPressed)` updates the state to reflect the changes.
    @MainActor
    func test_receive_accountPressed_alternateUnlocked() {
        let profile = ProfileSwitcherItem.fixture()
        let active = ProfileSwitcherItem.fixture()
        let account = Account.fixture(
            profile: .fixture(
                userId: profile.userId
            )
        )
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
        XCTAssertEqual(
            coordinator.events,
            [.action(.switchAccount(isAutomatic: false, userId: profile.userId))]
        )
    }

    /// `receive(_:)` with `.profileSwitcher(.accountPressed)` updates the state to reflect the changes.
    @MainActor
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
        XCTAssertEqual(
            coordinator.events,
            [.action(.switchAccount(isAutomatic: false, userId: profile.userId))]
        )
    }

    /// `receive(_:)` with `.profileSwitcher(.accountPressed)` updates the state to reflect the changes.
    @MainActor
    func test_receive_accountPressed_noMatch() {
        let profile = ProfileSwitcherItem.fixture()
        let active = ProfileSwitcherItem.fixture()
        authRepository.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, active],
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
        XCTAssertEqual(
            coordinator.events,
            [.action(.switchAccount(isAutomatic: false, userId: profile.userId))]
        )
    }

    /// `receive(_:)` with `.profileSwitcher(.addAccountPressed)` updates the state to reflect the changes.
    @MainActor
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
        waitFor(!subject.state.profileSwitcherState.isVisible)
        task.cancel()

        XCTAssertNotNil(subject.state.profileSwitcherState)
        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
        XCTAssertEqual(coordinator.routes, [])
    }

    /// `receive(_:)` with `.profileSwitcher(.backgroundPressed)` updates the state to reflect the changes.
    @MainActor
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

    /// `receive(_:)` with `.showPreLoginSettings` requests the coordinator navigate to the
    /// pre-login settings.
    @MainActor
    func test_receive_showPreLoginSettings() {
        subject.receive(.showPreLoginSettings)
        XCTAssertEqual(coordinator.routes, [.preLoginSettings])
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    @MainActor
    func test_receive_toastShown() {
        let toast = Toast(title: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }
} // swiftlint:disable:this file_length
