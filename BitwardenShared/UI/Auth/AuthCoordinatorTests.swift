import SwiftUI
import XCTest

// swiftlint:disable file_length

@testable import BitwardenShared

// MARK: - AuthCoordinatorTests

class AuthCoordinatorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authDelegate: MockAuthDelegate!
    var authRepository: MockAuthRepository!
    var errorReporter: MockErrorReporter!
    var rootNavigator: MockRootNavigator!
    var stackNavigator: MockStackNavigator!
    var stateService: MockStateService!
    var subject: AuthCoordinator!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        authDelegate = MockAuthDelegate()
        authRepository = MockAuthRepository()
        errorReporter = MockErrorReporter()
        rootNavigator = MockRootNavigator()
        stackNavigator = MockStackNavigator()
        stateService = MockStateService()
        vaultTimeoutService = MockVaultTimeoutService()
        subject = AuthCoordinator(
            appExtensionDelegate: MockAppExtensionDelegate(),
            delegate: authDelegate,
            rootNavigator: rootNavigator,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                errorReporter: errorReporter,
                stateService: stateService,
                vaultTimeoutService: vaultTimeoutService
            ),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()
        authDelegate = nil
        authRepository = nil
        errorReporter = nil
        rootNavigator = nil
        stackNavigator = nil
        stateService = nil
        vaultTimeoutService = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.alert` presents the provided alert on the stack navigator.
    func test_navigate_alert() {
        let alert = Alert(
            title: "title",
            message: "message",
            preferredStyle: .alert,
            alertActions: [
                AlertAction(
                    title: "alert title",
                    style: .cancel
                ),
            ]
        )

        subject.navigate(to: .alert(alert))
        XCTAssertEqual(stackNavigator.alerts.last, alert)
    }

    /// `navigate(to:)` with `.complete` notifies the delegate that auth has completed.
    func test_navigate_complete() {
        subject.navigate(to: .complete)
        XCTAssertTrue(authDelegate.didCompleteAuthCalled)
    }

    /// `navigate(to:)` with `.createAccount` pushes the create account view onto the stack navigator.
    func test_navigate_createAccount() throws {
        subject.navigate(to: .createAccount)

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<CreateAccountView>)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the presented view.
    func test_navigate_dismiss() throws {
        subject.navigate(to: .createAccount)
        subject.navigate(to: .dismiss)
        let lastAction = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(lastAction.type, .dismissed)
    }

    /// `navigate(to:)` with `.enterpriseSingleSignOn` pushes the enterprise single sign-on view onto the stack
    /// navigator.
    func test_navigate_enterpriseSingleSignOn() throws {
        subject.navigate(to: .enterpriseSingleSignOn(email: "email@example.com"))

        XCTAssertEqual(stackNavigator.actions.last?.type, .presented)
        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<SingleSignOnView>)
    }

    /// `navigate(to:)` with `.landing` pushes the landing view onto the stack navigator.
    func test_navigate_landing() {
        subject.navigate(to: .landing)
        XCTAssertTrue(stackNavigator.actions.last?.view is LandingView)
    }

    /// `navigate(to:)` with `.landing` from `.login` pops back to the landing view.
    func test_navigate_landing_fromLogin() {
        stackNavigator.viewControllersToPop = [
            UIViewController(),
        ]
        subject.navigate(to: .landing)

        XCTAssertEqual(stackNavigator.actions.last?.type, .poppedToRoot)
    }

    /// `navigate(to:)` with `.login` pushes the login view onto the stack navigator and hides the back button.
    func test_navigate_login() throws {
        subject.navigate(to: .login(
            username: "username",
            region: .unitedStates,
            isLoginWithDeviceVisible: true
        ))

        XCTAssertEqual(stackNavigator.actions.last?.type, .pushed)
        let viewController = try XCTUnwrap(
            stackNavigator.actions.last?.view as? UIHostingController<LoginView>
        )
        XCTAssertTrue(viewController.navigationItem.hidesBackButton)

        let view = viewController.rootView
        let state = view.store.state
        XCTAssertEqual(state.username, "username")
        XCTAssertEqual(state.region, .unitedStates)
        XCTAssertTrue(state.isLoginWithDeviceVisible)
    }

    /// `navigate(to:)` with `.loginOptions` pushes the login options view onto the stack navigator.
    func test_navigate_loginOptions() {
        subject.navigate(to: .loginOptions)
        XCTAssertTrue(stackNavigator.actions.last?.view is Text)
    }

    /// `navigate(to:)` with `.loginWithDevice` pushes the login with device view onto the stack navigator.
    func test_navigate_loginWithDevice() throws {
        subject.navigate(to: .loginWithDevice(email: "example@email.com"))

        XCTAssertEqual(stackNavigator.actions.last?.type, .presented)
        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<LoginWithDeviceView>)
    }

    /// `navigate(to:)` with `.masterPasswordHint` presents the master password hint view.
    func test_navigate_masterPasswordHint() throws {
        subject.navigate(to: .masterPasswordHint(username: "email@example.com"))

        XCTAssertEqual(stackNavigator.actions.last?.type, .presented)
        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<PasswordHintView>)
    }

    /// `navigate(to:)` with `.selfHosted` pushes the self-hosted view onto the stack navigator.
    func test_navigate_selfHosted() throws {
        subject.navigate(to: .selfHosted)

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<SelfHostedView>)
    }

    /// `navigate(to:)` with `.switchAccount` with an locked account navigates to vault unlock
    func test_navigate_switchAccount_locked() {
        let account = Account.fixture()
        authRepository.setActiveAccountResult = .success(account)
        vaultTimeoutService.timeoutStore = [account.profile.userId: true]
        stateService.activeAccount = account

        let task = Task {
            subject.navigate(to: .switchAccount(isUserInitiated: true, userId: account.profile.userId))
        }
        waitFor(stackNavigator.actions.last?.type == .replaced)
        task.cancel()
        XCTAssertTrue(stackNavigator.actions.last?.view is VaultUnlockView)
    }

    /// `navigate(to:)` with `.switchAccount` with an unlocked account triggers completion
    func test_navigate_switchAccount_unlocked() {
        let account = Account.fixture()
        authRepository.setActiveAccountResult = .success(account)
        authRepository.isLockedResult = .success(false)
        stateService.activeAccount = account

        let task = Task {
            subject.navigate(to: .switchAccount(isUserInitiated: true, userId: account.profile.userId))
        }
        waitFor(authDelegate.didCompleteAuthCalled)
        task.cancel()

        XCTAssertTrue(authDelegate.didCompleteAuthCalled)
    }

    /// `navigate(to:)` with `.switchAccount` with an unknown lock status account navigates to vault unlock.
    func test_navigate_switchAccount_unknownLock() {
        let account = Account.fixture()
        authRepository.setActiveAccountResult = .success(account)
        authRepository.isLockedResult = .failure(VaultTimeoutServiceError.noAccountFound)
        stateService.activeAccount = account

        let task = Task {
            subject.navigate(to: .switchAccount(isUserInitiated: true, userId: account.profile.userId))
        }
        waitFor(stackNavigator.actions.last?.view is VaultUnlockView)
        task.cancel()
        XCTAssertTrue(stackNavigator.actions.last?.view is VaultUnlockView)
    }

    /// `navigate(to:)` with `.switchAccount` with an invalid account navigates to landing view.
    func test_navigate_switchAccount_notFound() {
        let account = Account.fixture()
        let task = Task {
            subject.navigate(to: .switchAccount(isUserInitiated: true, userId: account.profile.userId))
        }
        waitFor(stackNavigator.actions.last?.view is LandingView)
        task.cancel()
        XCTAssertTrue(stackNavigator.actions.last?.view is LandingView)
    }

    /// `navigate(to:)` with `.twoFactor` shows the two factor auth view.
    func test_navigate_twoFactor() throws {
        subject.navigate(to: .twoFactor("", "", ["": ["": ""]]))

        XCTAssertEqual(stackNavigator.actions.last?.type, .presented)
        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<TwoFactorAuthView>)
    }

    /// `navigate(to:)` with `.vaultUnlock` replaces the current view with the vault unlock view.
    func test_navigate_vaultUnlock() throws {
        subject.navigate(
            to: .vaultUnlock(
                .fixture(),
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false
            )
        )

        XCTAssertEqual(stackNavigator.actions.last?.type, .replaced)
        let view: VaultUnlockView = try XCTUnwrap(stackNavigator.actions.last?.view as? VaultUnlockView)
        XCTAssertNil(view.store.state.toast)
    }

    /// `navigate(to:)` with `.vaultUnlock` replaces the current view with the vault unlock view.
    func test_navigate_vaultUnlock_withToast() throws {
        subject.navigate(
            to: .vaultUnlock(
                .fixture(),
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: true
            )
        )

        XCTAssertEqual(stackNavigator.actions.last?.type, .replaced)
        let view: VaultUnlockView = try XCTUnwrap(stackNavigator.actions.last?.view as? VaultUnlockView)
        waitFor(view.store.state.toast != nil)
        XCTAssertEqual(
            view.store.state.toast?.text,
            Localizations.accountSwitchedAutomatically
        )
    }

    /// `prepareAndRedirect(_ :)` redirects `.didDeleteAccount`.
    func test_prepareAndRedirect_didDeleteAccount_noAccounts() async {
        let route = await subject.prepareAndRedirect(.didDeleteAccount)
        XCTAssertEqual(route, .landing)
    }

    /// `prepareAndRedirect(_ :)` redirects `.didDeleteAccount`.
    func test_prepareAndRedirect_didDeleteAccount_alternateAccount() {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [
            alt,
        ]
        authRepository.setActiveAccountResult = .success(alt)
        var route: AuthRoute?
        let task = Task {
            route = await subject.prepareAndRedirect(.didDeleteAccount)
        }
        waitFor(authRepository.setActiveAccountId != nil)
        stateService.activeAccount = alt
        waitFor(route != nil)
        task.cancel()
        XCTAssertEqual(
            route,
            .vaultUnlock(
                alt,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: true
            )
        )
    }

    /// `prepareAndRedirect(_ :)` redirects `.didLogout()`.
    func test_prepareAndRedirect_didLogout_automatic_noAccounts() async {
        let route = await subject.prepareAndRedirect(.didLogout(userInitiated: false))
        XCTAssertEqual(route, .landing)
    }

    /// `prepareAndRedirect(_ :)` redirects `.didLogout()`.
    func test_prepareAndRedirect_didLogout_automatic_alternateAccount() async {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [
            alt,
        ]
        authRepository.setActiveAccountResult = .success(alt)
        let route = await subject.prepareAndRedirect(.didLogout(userInitiated: false))
        XCTAssertEqual(route, .landing)
    }

    /// `prepareAndRedirect(_ :)` redirects `.didLogout()`.
    func test_prepareAndRedirect_didLogout_userInitiated_noAccounts() async {
        let route = await subject.prepareAndRedirect(.didLogout(userInitiated: true))
        XCTAssertEqual(route, .landing)
    }

    /// `prepareAndRedirect(_ :)` redirects `.didLogout()`.
    func test_prepareAndRedirect_didLogout_userInitiated_alternateAccount() {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [
            alt,
        ]
        authRepository.setActiveAccountResult = .success(alt)
        var route: AuthRoute?
        let task = Task {
            route = await subject.prepareAndRedirect(.didLogout(userInitiated: true))
        }
        waitFor(authRepository.setActiveAccountId != nil)
        stateService.activeAccount = alt
        waitFor(route != nil)
        task.cancel()
        XCTAssertEqual(
            route,
            .vaultUnlock(
                alt,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: true
            )
        )
    }

    /// `prepareAndRedirect(_ :)` redirects `.didStart`.
    func test_prepareAndRedirect_didStart_noAccounts() async {
        let route = await subject.prepareAndRedirect(.didStart)
        XCTAssertEqual(route, .landing)
    }

    /// `prepareAndRedirect(_ :)` redirects `.didStart`.
    func test_prepareAndRedirect_didStart_alternateAccount() async {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [
            alt,
        ]
        authRepository.setActiveAccountResult = .success(alt)
        let route = await subject.prepareAndRedirect(.didStart)
        XCTAssertEqual(
            route,
            .vaultUnlock(
                alt,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false
            )
        )
    }

    /// `prepareAndRedirect(_ :)` redirects `.didStart`.
    func test_prepareAndRedirect_didStart_timeoutOnAppRestart_lock() async {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [
            alt,
        ]
        stateService.activeAccount = alt
        vaultTimeoutService.vaultTimeout = [
            alt.profile.userId: .onAppRestart,
        ]
        let route = await subject.prepareAndRedirect(.didStart)
        XCTAssertEqual(
            route,
            .vaultUnlock(
                alt,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false
            )
        )
    }

    /// `prepareAndRedirect(_ :)` redirects `.didStart`.
    func test_prepareAndRedirect_didStart_timeoutOnAppRestart_logout() async {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [
            alt,
        ]
        stateService.activeAccount = alt
        vaultTimeoutService.vaultTimeout = [
            alt.profile.userId: .onAppRestart,
        ]
        stateService.timeoutAction = [
            alt.profile.userId: .logout,
        ]
        authRepository.logoutResult = .success(())
        let route = await subject.prepareAndRedirect(.didStart)
        XCTAssertEqual(
            route,
            .landing
        )
    }

    /// `prepareAndRedirect(_ :)` redirects `.didTimeout`.
    func test_prepareAndRedirect_didTimeout_noAccounts() async {
        let route = await subject.prepareAndRedirect(.didTimeout(userId: "123"))
        XCTAssertEqual(route, .didTimeout(userId: "123"))
    }

    /// `prepareAndRedirect(_ :)` redirects `.didTimeout`.
    func test_prepareAndRedirect_didTimeout_neverLock() async {
        vaultTimeoutService.vaultTimeout = [
            "123": .never,
        ]
        let route = await subject.prepareAndRedirect(.didTimeout(userId: "123"))
        XCTAssertEqual(route, .didTimeout(userId: "123"))
    }

    /// `prepareAndRedirect(_ :)` redirects `.didStart`.
    func test_prepareAndRedirect_didTimeout_lock() async {
        let account = Account.fixture()
        stateService.accounts = [
            account,
        ]
        stateService.activeAccount = account
        vaultTimeoutService.vaultTimeout = [
            account.profile.userId: .fiveMinutes,
        ]
        stateService.timeoutAction = [
            account.profile.userId: .lock,
        ]
        authRepository.logoutResult = .success(())
        let route = await subject.prepareAndRedirect(.didTimeout(userId: account.profile.userId))
        XCTAssertEqual(
            route,
            .vaultUnlock(
                account,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false
            )
        )
    }

    /// `prepareAndRedirect(_ :)` redirects `.didStart`.
    func test_prepareAndRedirect_didTimeout_logout() async {
        let account = Account.fixture()
        stateService.accounts = [
            account,
        ]
        stateService.activeAccount = account
        vaultTimeoutService.vaultTimeout = [
            account.profile.userId: .fiveMinutes,
        ]
        stateService.timeoutAction = [
            account.profile.userId: .logout,
        ]
        authRepository.logoutResult = .success(())
        let route = await subject.prepareAndRedirect(.didTimeout(userId: account.profile.userId))
        XCTAssertEqual(
            route,
            .landing
        )
    }

    /// `prepareAndRedirect(_ :)` redirects `.didStart`.
    func test_prepareAndRedirect_didTimeout_logout_error() async {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [
            account,
        ]
        stateService.activeAccount = account
        vaultTimeoutService.vaultTimeout = [
            account.profile.userId: .fiveMinutes,
        ]
        stateService.timeoutAction = [
            account.profile.userId: .logout,
        ]
        authRepository.logoutResult = .failure(BitwardenTestError.example)
        let route = await subject.prepareAndRedirect(.didTimeout(userId: account.profile.userId))
        XCTAssertEqual(
            route,
            .landing
        )
    }

    /// `prepareAndRedirect(_ :)` redirects `.didDeleteAccount`.
    func test_prepareAndRedirect_didDeleteAccount_setActiveFail() async {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [
            alt,
        ]
        authRepository.setActiveAccountResult = .failure(BitwardenTestError.example)
        let route = await subject.prepareAndRedirect(.didDeleteAccount)
        XCTAssertEqual(
            route,
            .landing
        )
    }

    /// `prepareAndRedirect(_ :)` redirects `.vaultUnlock()`.
    func test_prepareAndRedirect_vaultUnlock_neverLock_error() async {
        let active = Account.fixture()
        stateService.activeAccount = active
        authRepository.isLockedResult = .success(true)
        vaultTimeoutService.vaultTimeout = [
            active.profile.userId: .never,
        ]
        authRepository.unlockVaultWithNeverlockResult = .failure(BitwardenTestError.example)
        let initialRoute = AuthRoute.vaultUnlock(
            active,
            animated: true,
            attemptAutomaticBiometricUnlock: true,
            didSwitchAccountAutomatically: false
        )
        let route = await subject.prepareAndRedirect(
            initialRoute
        )
        XCTAssertEqual(route, initialRoute)
        let error = try? XCTUnwrap(errorReporter.errors.first as? BitwardenTestError)
        XCTAssertEqual(BitwardenTestError.example, error)
    }

    /// `prepareAndRedirect(_ :)` redirects `.vaultUnlock()`.
    func test_prepareAndRedirect_vaultUnlock_neverLock_success() async {
        let active = Account.fixture()
        stateService.activeAccount = active
        authRepository.isLockedResult = .success(true)
        vaultTimeoutService.vaultTimeout = [
            active.profile.userId: .never,
        ]
        authRepository.unlockVaultWithNeverlockResult = .success(())
        let route = await subject.prepareAndRedirect(
            .vaultUnlock(
                active,
                animated: true,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false
            )
        )
        XCTAssertEqual(route, .complete)
    }

    /// `prepareAndRedirect(_ :)` redirects `.vaultUnlock()`.
    func test_prepareAndRedirect_vaultUnlock_unlocked() async {
        let active = Account.fixture()
        stateService.activeAccount = active
        authRepository.isLockedResult = .success(false)
        let route = await subject.prepareAndRedirect(
            .vaultUnlock(
                active,
                animated: true,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false
            )
        )
        XCTAssertEqual(route, .complete)
    }

    /// `rootNavigator` uses a weak reference and does not retain a value once the root navigator has been erased.
    func test_rootNavigator_resetWeakReference() {
        var rootNavigator: MockRootNavigator? = MockRootNavigator()
        subject = AuthCoordinator(
            appExtensionDelegate: MockAppExtensionDelegate(),
            delegate: authDelegate,
            rootNavigator: rootNavigator!,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
        )
        XCTAssertNotNil(subject.rootNavigator)

        rootNavigator = nil
        XCTAssertNil(subject.rootNavigator)
    }

    /// `showLoadingOverlay()` and `hideLoadingOverlay()` can be used to show and hide the loading overlay.
    func test_show_hide_loadingOverlay() throws {
        stackNavigator.rootViewController = UIViewController()
        try setKeyWindowRoot(viewController: XCTUnwrap(subject.stackNavigator?.rootViewController))

        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.showLoadingOverlay(LoadingOverlayState(title: "Loading..."))
        XCTAssertNotNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.hideLoadingOverlay()
        waitFor { window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag) == nil }
        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))
    }

    /// `start()` presents the stack navigator within the root navigator.
    func test_start() {
        subject.start()
        XCTAssertIdentical(rootNavigator.navigatorShown, stackNavigator)
    }
}

// MARK: - MockAuthDelegate

class MockAuthDelegate: AuthCoordinatorDelegate {
    var didCompleteAuthCalled = false

    func didCompleteAuth() {
        didCompleteAuthCalled = true
    }
}
