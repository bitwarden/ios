import XCTest

// swiftlint:disable file_length

@testable import BitwardenShared

final class AuthRouterTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: AuthRouter!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = AuthRouter(
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                errorReporter: errorReporter,
                stateService: stateService,
                vaultTimeoutService: vaultTimeoutService
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        errorReporter = nil
        stateService = nil
        subject = nil
        vaultTimeoutService = nil
    }

    /// `handleAndRoute(_ :)` redirects `.didDeleteAccount`.
    func test_handleAndRoute_didDeleteAccount_noAccounts() async {
        let route = await subject.handleAndRoute(.didDeleteAccount)
        XCTAssertEqual(route, .landing)
    }

    /// `handleAndRoute(_ :)` redirects `.didDeleteAccount`.
    func test_handleAndRoute_didDeleteAccount_alternateAccount() {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [
            alt,
        ]
        authRepository.altAccounts = [alt]
        var route: AuthRoute?
        let task = Task {
            route = await subject.handleAndRoute(.didDeleteAccount)
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

    /// `handleAndRoute(_ :)` redirects `.didLockAccount()`.
    func test_handleAndRoute_didLockAccount_active() async {
        let alt = Account.fixtureAccountLogin()
        let active = Account.fixture()
        authRepository.activeAccount = active
        authRepository.altAccounts = [
            alt,
        ]
        stateService.accounts = [
            alt,
        ]
        let route = await subject.handleAndRoute(
            .didLockAccount(
                active,
                animated: false,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false
            )
        )

        XCTAssertEqual(
            route,
            .vaultUnlock(
                active,
                animated: false,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false
            )
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didLockAccount()`.
    func test_handleAndRoute_didLockAccount_alternate() async {
        let alt = Account.fixtureAccountLogin()
        let active = Account.fixture()
        authRepository.activeAccount = active
        authRepository.altAccounts = [
            alt,
        ]
        authRepository.isLockedResult = .success(false)
        let route = await subject.handleAndRoute(
            .didLockAccount(
                alt,
                animated: false,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false
            )
        )

        XCTAssertEqual(
            route,
            .complete
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()`.
    func test_handleAndRoute_didLogout_automatic_noAccounts() async {
        let route = await subject.handleAndRoute(.didLogout(userId: "123", userInitiated: false))
        XCTAssertEqual(route, .landing)
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()`.
    func test_handleAndRoute_didLogout_automatic_alternateAccount() async {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [
            alt,
        ]
        authRepository.altAccounts = [alt]
        let route = await subject.handleAndRoute(.didLogout(userId: alt.profile.userId, userInitiated: false))
        XCTAssertEqual(route, .landing)
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()`.
    func test_handleAndRoute_didLogout_userInitiated_noAccounts() async {
        let route = await subject.handleAndRoute(.didLogout(userId: "123", userInitiated: true))
        XCTAssertEqual(route, .landing)
    }

    /// `handleAndRoute(_ :)` redirects `.logout()`.
    func test_handleAndRoute_logout_userInitiated_alternateAccount_locked() async {
        let alt = Account.fixtureAccountLogin()
        let main = Account.fixture()
        authRepository.activeAccount = main
        authRepository.isLockedResult = .success(true)
        authRepository.altAccounts = [
            alt,
        ]
        stateService.accounts = [
            main,
        ]

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: alt.profile.userId,
                    userInitiated: true
                )
            )
        )

        XCTAssertEqual(
            route,
            .vaultUnlock(
                main,
                animated: false,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false
            )
        )
    }

    /// `handleAndRoute(_ :)` redirects `.logout()`.
    func test_handleAndRoute_logout_userInitiated_alternateAccount_unlocked() async {
        let alt = Account.fixtureAccountLogin()
        let main = Account.fixture()
        authRepository.activeAccount = main
        authRepository.isLockedResult = .success(false)
        authRepository.altAccounts = [
            alt,
        ]
        stateService.accounts = [
            main,
        ]

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: alt.profile.userId,
                    userInitiated: true
                )
            )
        )

        XCTAssertEqual(
            route,
            .complete
        )
    }

    /// `handleAndRoute(_ :)` redirects `.logout()`.
    func test_handleAndRoute_logout_userInitiated_main_locked() async {
        let alt = Account.fixtureAccountLogin()
        let main = Account.fixture()
        authRepository.activeAccount = main
        authRepository.isLockedResult = .success(true)
        authRepository.altAccounts = [
            alt,
        ]
        stateService.accounts = [
            alt,
        ]

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: main.profile.userId,
                    userInitiated: true
                )
            )
        )

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

    /// `handleAndRoute(_ :)` redirects `.logout()`.
    func test_handleAndRoute_logout_userInitiated_nil_locked() async {
        let alt = Account.fixtureAccountLogin()
        authRepository.activeAccount = nil
        authRepository.isLockedResult = .success(true)
        authRepository.altAccounts = [
            alt,
        ]
        stateService.accounts = [
            alt,
        ]

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: "123",
                    userInitiated: true
                )
            )
        )

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

    /// `handleAndRoute(_ :)` redirects `.logout()`.
    func test_handleAndRoute_logout_userInitiated_notFound_locked() async {
        let main = Account.fixture()
        let alt = Account.fixtureAccountLogin()
        authRepository.activeAccount = main
        authRepository.isLockedResult = .success(true)
        authRepository.altAccounts = []
        stateService.accounts = [
            main,
        ]

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: "123",
                    userInitiated: true
                )
            )
        )

        XCTAssertEqual(
            route,
            .vaultUnlock(
                main,
                animated: false,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false
            )
        )
    }

    /// `handleAndRoute(_ :)` redirects `.logout()`.
    func test_handleAndRoute_logout_system_nil_locked() async {
        let main = Account.fixture()
        let alt = Account.fixtureAccountLogin()
        authRepository.activeAccount = nil
        authRepository.isLockedResult = .success(true)
        authRepository.altAccounts = []
        stateService.accounts = [
            main,
        ]

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: "123",
                    userInitiated: false
                )
            )
        )

        XCTAssertEqual(
            route,
            .landing
        )
    }

    /// `handleAndRoute(_ :)` redirects `.logout()`.
    func test_handleAndRoute_logout_system_active_noAlt() async {
        let main = Account.fixture()
        authRepository.activeAccount = main
        authRepository.altAccounts = []
        stateService.accounts = []

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: main.profile.userId,
                    userInitiated: false
                )
            )
        )

        XCTAssertEqual(
            route,
            .landing
        )
    }

    /// `handleAndRoute(_ :)` redirects `.logout()`.
    func test_handleAndRoute_logout_system_active_noAlt_error() async {
        let main = Account.fixture()
        authRepository.activeAccount = main
        authRepository.altAccounts = []
        authRepository.logoutResult = .failure(BitwardenTestError.example)
        stateService.accounts = []

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: main.profile.userId,
                    userInitiated: false
                )
            )
        )

        XCTAssertEqual(
            route,
            .vaultUnlock(
                main,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false
            )
        )
    }

    /// `handleAndRoute(_ :)` redirects `.logout()`.
    func test_handleAndRoute_logout_system_active_nil_error() async {
        let main = Account.fixture()
        authRepository.activeAccount = nil
        authRepository.altAccounts = [main]
        authRepository.logoutResult = .failure(BitwardenTestError.example)
        stateService.accounts = [.fixture()]

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: main.profile.userId,
                    userInitiated: false
                )
            )
        )

        XCTAssertEqual(
            route,
            .landing
        )
    }

    /// `handleAndRoute(_ :)` redirects `.logout()`.
    func test_handleAndRoute_logout_userInitiated_main_unlocked() async {
        let alt = Account.fixtureAccountLogin()
        let main = Account.fixture()
        authRepository.activeAccount = main
        authRepository.isLockedResult = .success(false)
        authRepository.altAccounts = [
            alt,
        ]
        stateService.accounts = [
            alt,
        ]

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: main.profile.userId,
                    userInitiated: true
                )
            )
        )

        XCTAssertEqual(
            route,
            .complete
        )
    }

    /// `handleAndRoute(_ :)` redirects `.logout()`.
    func test_handleAndRoute_lock_main() async {
        let main = Account.fixture()
        authRepository.activeAccount = main
        authRepository.isLockedResult = .success(true)

        let route = await subject.handleAndRoute(
            .action(
                .lockVault(userId: main.profile.userId)
            )
        )

        XCTAssertEqual(
            route,
            .vaultUnlock(
                main,
                animated: false,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false
            )
        )
    }

    /// `handleAndRoute(_ :)` redirects `.logout()`.
    func test_handleAndRoute_lock_alternate() async {
        let main = Account.fixture()
        let alt = Account.fixtureAccountLogin()
        authRepository.activeAccount = main
        authRepository.altAccounts = [alt]

        let route = await subject.handleAndRoute(
            .action(
                .lockVault(userId: alt.profile.userId)
            )
        )

        XCTAssertEqual(
            route,
            .vaultUnlock(
                main,
                animated: false,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false
            )
        )
    }

    /// `handleAndRoute(_ :)` redirects `.logout()`.
    func test_handleAndRoute_lock_unknown() async {
        let main = Account.fixture()
        authRepository.activeAccount = main
        authRepository.altAccounts = []

        let route = await subject.handleAndRoute(
            .action(
                .lockVault(
                    userId: Account.fixtureAccountLogin().profile.userId
                )
            )
        )

        XCTAssertEqual(
            route,
            .vaultUnlock(
                main,
                animated: false,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false
            )
        )
    }

    /// `handleAndRoute(_ :)` redirects `.logout()`.
    func test_handleAndRoute_lock_noAccounts() async {
        authRepository.activeAccount = nil
        authRepository.altAccounts = []

        let route = await subject.handleAndRoute(
            .action(
                .lockVault(
                    userId: Account.fixtureAccountLogin().profile.userId
                )
            )
        )

        XCTAssertEqual(
            route,
            .landing
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()`.
    func test_handleAndRoute_didLogout_userInitiated_alternateAccount() {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [
            alt,
        ]
        authRepository.altAccounts = [alt]
        var route: AuthRoute?
        let task = Task {
            route = await subject.handleAndRoute(
                .didLogout(
                    userId: "123",
                    userInitiated: true
                )
            )
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

    /// `handleAndRoute(_ :)` redirects `.didStart`.
    func test_handleAndRoute_didStart_noAccounts() async {
        let route = await subject.handleAndRoute(.didStart)
        XCTAssertEqual(route, .landing)
    }

    /// `handleAndRoute(_ :)` redirects `.didStart`.
    func test_handleAndRoute_didStart_alternateAccount() async {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [
            alt,
        ]
        authRepository.altAccounts = [alt]
        let route = await subject.handleAndRoute(.didStart)
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

    /// `handleAndRoute(_ :)` redirects `.didStart`.
    func test_handleAndRoute_didStart_timeoutOnAppRestart_lock() async {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [
            alt,
        ]
        stateService.activeAccount = alt
        vaultTimeoutService.vaultTimeout = [
            alt.profile.userId: .onAppRestart,
        ]
        let route = await subject.handleAndRoute(.didStart)
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

    /// `handleAndRoute(_ :)` redirects `.didStart`.
    func test_handleAndRoute_didStart_timeoutOnAppRestart_logout() async {
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
        let route = await subject.handleAndRoute(.didStart)
        XCTAssertEqual(
            route,
            .landing
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didTimeout`.
    func test_handleAndRoute_didTimeout_noAccounts() async {
        let route = await subject.handleAndRoute(.didTimeout(userId: "123"))
        XCTAssertEqual(route, .complete)
    }

    /// `handleAndRoute(_ :)` redirects `.didTimeout`.
    func test_handleAndRoute_didTimeout_neverLock() async {
        vaultTimeoutService.vaultTimeout = [
            "123": .never,
        ]
        let route = await subject.handleAndRoute(.didTimeout(userId: "123"))
        XCTAssertEqual(route, .complete)
    }

    /// `handleAndRoute(_ :)` redirects `.didStart`.
    func test_handleAndRoute_didTimeout_lock() async {
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
        let route = await subject.handleAndRoute(.didTimeout(userId: account.profile.userId))
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

    /// `handleAndRoute(_ :)` redirects `.didStart`.
    func test_handleAndRoute_didTimeout_logout() async {
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
        let route = await subject.handleAndRoute(.didTimeout(userId: account.profile.userId))
        XCTAssertEqual(
            route,
            .landing
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didStart`.
    func test_handleAndRoute_didTimeout_logout_error() async {
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
        let route = await subject.handleAndRoute(.didTimeout(userId: account.profile.userId))
        XCTAssertEqual(
            route,
            .landing
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didDeleteAccount`.
    func test_handleAndRoute_didDeleteAccount_setActiveFail() async {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [
            alt,
        ]
        authRepository.setVaultTimeoutError = BitwardenTestError.example
        let route = await subject.handleAndRoute(.didDeleteAccount)
        XCTAssertEqual(
            route,
            .landing
        )
    }

    /// `handleAndRoute(_ :)` redirects `.accountBecameActive()`.
    func test_handleAndRoute_accountBecameActive_neverLock_error() async {
        let active = Account.fixture()
        stateService.activeAccount = active
        authRepository.isLockedResult = .success(true)
        vaultTimeoutService.vaultTimeout = [
            active.profile.userId: .never,
        ]
        authRepository.unlockVaultWithNeverlockResult = .failure(BitwardenTestError.example)
        let initialRoute = AuthEvent.accountBecameActive(
            active,
            animated: true,
            attemptAutomaticBiometricUnlock: true,
            didSwitchAccountAutomatically: false
        )
        let route = await subject.handleAndRoute(
            initialRoute
        )
        XCTAssertEqual(
            route,
            .vaultUnlock(
                active,
                animated: true,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false
            )
        )
        let error = try? XCTUnwrap(errorReporter.errors.first as? BitwardenTestError)
        XCTAssertEqual(BitwardenTestError.example, error)
    }

    /// `handleAndRoute(_ :)` redirects `.vaultUnlock()`.
    func test_handleAndRoute_accountBecameActive_neverLock_success() async {
        let active = Account.fixture()
        stateService.activeAccount = active
        authRepository.isLockedResult = .success(true)
        vaultTimeoutService.vaultTimeout = [
            active.profile.userId: .never,
        ]
        authRepository.unlockVaultWithNeverlockResult = .success(())
        let route = await subject.handleAndRoute(
            .accountBecameActive(
                active,
                animated: true,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false
            )
        )
        XCTAssertEqual(route, .complete)
    }

    /// `handleAndRoute(_ :)` redirects `.vaultUnlock()`.
    func test_handleAndRoute_accountBecameActive_unlocked() async {
        let active = Account.fixture()
        stateService.activeAccount = active
        authRepository.isLockedResult = .success(false)
        let route = await subject.handleAndRoute(
            .accountBecameActive(
                active,
                animated: true,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false
            )
        )
        XCTAssertEqual(route, .complete)
    }

    /// `handleAndRoute(_ :)` redirects `.didStart`.
    func test_handleAndRoute_switchAccount_toActive() async {
        let active = Account.fixture()
        authRepository.activeAccount = active
        authRepository.isLockedResult = .success(false)
        let route = await subject.handleAndRoute(
            .action(
                .switchAccount(isAutomatic: true, userId: active.profile.userId)
            )
        )
        XCTAssertEqual(route, .complete)
    }

    /// `handleAndRoute(_ :)` redirects `.didStart`.
    func test_handleAndRoute_switchAccount_error() async {
        let active = Account.fixture()
        authRepository.activeAccount = active
        authRepository.altAccounts = [.fixture(profile: .fixture(userId: "2"))]
        authRepository.isLockedResult = .success(false)
        authRepository.setActiveAccountError = BitwardenTestError.example
        let route = await subject.handleAndRoute(.action(.switchAccount(isAutomatic: true, userId: "2")))
        XCTAssertEqual(route, .landing)
    }
}
