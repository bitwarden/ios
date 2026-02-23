import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

// swiftlint:disable file_length

@testable import BitwardenShared
@testable import BitwardenSharedMocks

@MainActor
final class AuthRouterTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var biometricsRepository: MockBiometricsRepository!
    var configService: MockConfigService!
    var errorReporter: MockErrorReporter!
    var rehydrationHelper: MockRehydrationHelper!
    var stateService: MockStateService!
    var subject: AuthRouter!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        biometricsRepository = MockBiometricsRepository()
        configService = MockConfigService()
        errorReporter = MockErrorReporter()
        rehydrationHelper = MockRehydrationHelper()
        stateService = MockStateService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = AuthRouter(
            isInAppExtension: false,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                biometricsRepository: biometricsRepository,
                configService: configService,
                errorReporter: errorReporter,
                rehydrationHelper: rehydrationHelper,
                stateService: stateService,
                vaultTimeoutService: vaultTimeoutService,
            ),
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()

        authRepository = nil
        biometricsRepository = nil
        configService = nil
        errorReporter = nil
        rehydrationHelper = nil
        stateService = nil
        subject = nil
        vaultTimeoutService = nil
    }

    /// `handleAndRoute(_ :)` redirects `.accountBecameActive()` to `.vaultUnlock`
    ///     when `unlockVaultWithNeverlockResult` fails.
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
            didSwitchAccountAutomatically: false,
        )
        let route = await subject.handleAndRoute(
            initialRoute,
        )
        XCTAssertEqual(
            route,
            .vaultUnlock(
                active,
                animated: true,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false,
            ),
        )
        let error = try? XCTUnwrap(errorReporter.errors.first as? BitwardenTestError)
        XCTAssertEqual(BitwardenTestError.example, error)
    }

    /// `handleAndRoute(_ :)` redirects `.accountBecameActive()` to `.completeWithNeverUnlockKey`
    ///     when `unlockVaultWithNeverlockResult` succeeds.
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
                didSwitchAccountAutomatically: false,
            ),
        )
        XCTAssertEqual(route, .completeWithNeverUnlockKey)
    }

    /// `handleAndRoute(_ :)` redirects `.accountBecameActive()` to `.vaultUnlock`
    /// when timeout `.never` and manually locked.
    func test_handleAndRoute_accountBecameActive_neverLock_successOnManuallyLocked() async {
        let active = Account.fixture()
        stateService.activeAccount = active
        stateService.isAuthenticated[active.profile.userId] = true
        authRepository.isLockedResult = .success(true)
        vaultTimeoutService.vaultTimeout = [
            active.profile.userId: .never,
        ]
        authRepository.unlockVaultWithNeverlockResult = .success(())
        stateService.manuallyLockedAccounts[active.profile.userId] = true
        let route = await subject.handleAndRoute(
            .accountBecameActive(
                active,
                animated: true,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false,
            ),
        )
        XCTAssertEqual(
            route,
            .vaultUnlock(
                active,
                animated: true,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false,
            ),
        )
    }

    /// `handleAndRoute(_ :)` redirects `.accountBecameActive()` to `.complete`
    ///     when the account is unlocked.
    func test_handleAndRoute_accountBecameActive_unlocked() async {
        let active = Account.fixture()
        stateService.activeAccount = active
        authRepository.isLockedResult = .success(false)
        let route = await subject.handleAndRoute(
            .accountBecameActive(
                active,
                animated: true,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false,
            ),
        )
        XCTAssertEqual(route, .complete)
    }

    /// `handleAndRoute(_ :)` redirects `.accountBecameActive()` to `.vaultUnlock` when checking if
    /// an account is authenticated fails.
    func test_handleAndRoute_accountBecameActive_logout_isAuthenticatedError() async {
        let account = Account.fixtureAccountLogin()
        authRepository.activeAccount = account
        authRepository.isLockedResult = .success(true)
        authRepository.sessionTimeoutAction[account.profile.userId] = .logout
        stateService.isAuthenticatedError = BitwardenTestError.example

        let route = await subject.handleAndRoute(
            .accountBecameActive(
                account,
                animated: true,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false,
            ),
        )

        XCTAssertEqual(
            route,
            .vaultUnlock(
                account,
                animated: true,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false,
            ),
        )
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `handleAndRoute(_ :)` redirects `.didCompleteAuth` to `.landing` and sets the carousel shown
    /// flag if the carousel hasn't been shown yet.
    func test_handleAndRoute_didCompleteAuth_carouselShown() async {
        authRepository.activeAccount = .fixture()

        let route = await subject.handleAndRoute(.didCompleteAuth)

        XCTAssertEqual(route, .complete)
        XCTAssertTrue(stateService.introCarouselShown)
    }

    /// `handleAndRoute(_ :)` redirects `.didCompleteAuth` to `.vaultUnlockSetup` and sets the
    /// carousel shown flag and the carousel hasn't been shown yet.
    func test_handleAndRoute_didCompleteAuth_carouselShown_vaultUnlockSetup() async {
        authRepository.activeAccount = .fixture()
        stateService.activeAccount = .fixture()
        stateService.accountSetupVaultUnlock["1"] = .incomplete

        let route = await subject.handleAndRoute(.didCompleteAuth)

        XCTAssertEqual(route, .vaultUnlockSetup(.createAccount))
        XCTAssertTrue(stateService.introCarouselShown)
    }

    /// `handleAndRoute(_:)` redirects `.didCompleteAuth` to complete the auth flow if the account
    /// doesn't require an updated password.
    func test_handleAndRoute_didCompleteAuth_complete() async {
        authRepository.activeAccount = .fixture()
        let route = await subject.handleAndRoute(.didCompleteAuth)
        XCTAssertEqual(route, .complete)
    }

    /// `handleAndRoute(_:)` redirects `.didCompleteAuth` to complete with rehydration the auth flow if the account
    /// doesn't require an updated password and there's a rehydratable target saved.
    func test_handleAndRoute_didCompleteAuth_completeWithRehydration() async {
        authRepository.activeAccount = .fixture()
        rehydrationHelper.getSavedRehydratableTargetResult = .success(.viewCipher(cipherId: "1"))
        let route = await subject.handleAndRoute(.didCompleteAuth)
        XCTAssertEqual(route, .completeWithRehydration(.viewCipher(cipherId: "1")))
    }

    /// `handleAndRoute(_:)` redirects `.didCompleteAuth` to complete the auth flow if the account
    /// doesn't require an updated password when getting the saved rehydratable target throws, logging its error.
    func test_handleAndRoute_didCompleteAuth_completeRehydrationThrows() async {
        authRepository.activeAccount = .fixture()
        rehydrationHelper.getSavedRehydratableTargetResult = .failure(BitwardenTestError.example)
        let route = await subject.handleAndRoute(.didCompleteAuth)
        XCTAssertEqual(route, .complete)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `handleAndRoute(_:)` redirects `.didCompleteAuth` to complete the auth flow if the account
    /// doesn't require an updated password and there's a rehydratable target saved
    /// but it's in the app extension context.
    func test_handleAndRoute_didCompleteAuth_completeWithRehydrationNotCalledAppExtension() async {
        subject = AuthRouter(
            isInAppExtension: true,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                biometricsRepository: biometricsRepository,
                configService: configService,
                errorReporter: errorReporter,
                rehydrationHelper: rehydrationHelper,
                stateService: stateService,
                vaultTimeoutService: vaultTimeoutService,
            ),
        )

        authRepository.activeAccount = .fixture()
        rehydrationHelper.getSavedRehydratableTargetResult = .success(.viewCipher(cipherId: "1"))
        let route = await subject.handleAndRoute(.didCompleteAuth)
        XCTAssertEqual(route, .complete)
    }

    /// `handleAndRoute(_:)` redirects `.didCompleteAuth` to `.autofillSetup` if the user still
    /// needs to set up autofill.
    func test_handleAndRoute_didCompleteAuth_incompleteAutofill() async {
        authRepository.activeAccount = .fixture()
        stateService.activeAccount = .fixture()
        stateService.accountSetupAutofill["1"] = .incomplete
        let route = await subject.handleAndRoute(.didCompleteAuth)
        XCTAssertEqual(route, .autofillSetup)
    }

    /// `handleAndRoute(_:)` redirects `.didCompleteAuth` to `.complete` if the user still
    /// needs to set up autofill but is within the app extension.
    func test_handleAndRoute_didCompleteAuth_incompleteAutofill_withinAppExtension() async {
        subject = AuthRouter(
            isInAppExtension: true,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
            ),
        )
        authRepository.activeAccount = .fixture()
        stateService.activeAccount = .fixture()
        stateService.accountSetupAutofill["1"] = .incomplete
        let route = await subject.handleAndRoute(.didCompleteAuth)
        XCTAssertEqual(route, .complete)
    }

    /// `handleAndRoute(_:)` redirects `.didCompleteAuth` to `.vaultUnlockSetup` if the user still
    /// needs to set up a vault unlock method.
    func test_handleAndRoute_didCompleteAuth_incompleteVaultSetup() async {
        authRepository.activeAccount = .fixture()
        stateService.activeAccount = .fixture()
        stateService.accountSetupVaultUnlock["1"] = .incomplete
        let route = await subject.handleAndRoute(.didCompleteAuth)
        XCTAssertEqual(route, .vaultUnlockSetup(.createAccount))
    }

    /// `handleAndRoute(_:)` redirects `.didCompleteAuth` to `.complete` if the user still
    /// needs to set up a vault unlock method but is within the app extension.
    func test_handleAndRoute_didCompleteAuth_incomplete_withinAppExtension() async {
        subject = AuthRouter(
            isInAppExtension: true,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
            ),
        )
        authRepository.activeAccount = .fixture()
        stateService.activeAccount = .fixture()
        stateService.accountSetupVaultUnlock["1"] = .incomplete
        let route = await subject.handleAndRoute(.didCompleteAuth)
        XCTAssertEqual(route, .complete)
    }

    /// `handleAndRoute(_ :)` redirects `.didCompleteAuth` to `.landing` when there are no accounts.
    func test_handleAndRoute_didCompleteAuth_noAccounts() async {
        let route = await subject.handleAndRoute(.didCompleteAuth)
        XCTAssertEqual(route, .landing)
    }

    /// `handleAndRoute(_:)` redirects `.didCompleteAuth` to the update master password screen if
    /// the account requires an updated password.
    func test_handleAndRoute_didCompleteAuth_updatePassword() async {
        authRepository.activeAccount = .fixture(
            profile: .fixture(forcePasswordResetReason: .adminForcePasswordReset),
        )
        let route = await subject.handleAndRoute(.didCompleteAuth)
        XCTAssertEqual(route, .updateMasterPassword)
    }

    /// `handleAndRoute(_ :)` redirects`.didDeleteAccount` to another account
    ///     when there are more accounts.
    func test_handleAndRoute_didDeleteAccount_alternateAccount() async {
        let activeAccount = Account.fixture()
        stateService.activeAccount = activeAccount
        stateService.isAuthenticated[activeAccount.profile.userId] = true
        authRepository.altAccounts = [activeAccount]

        let route = await subject.handleAndRoute(.didDeleteAccount)

        XCTAssertEqual(
            route,
            .vaultUnlock(
                activeAccount,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: true,
            ),
        )
        XCTAssertEqual(authRepository.activeAccount, activeAccount)
    }

    /// `handleAndRoute(_ :)` redirects`.didDeleteAccount` to `.landing`
    ///     when there are no more accounts.
    func test_handleAndRoute_didDeleteAccount_noAccounts() async {
        let route = await subject.handleAndRoute(.didDeleteAccount)
        XCTAssertEqual(route, .landing)
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `handleAndRoute(_ :)` redirects`.didDeleteAccount` to `.landing`
    ///     when an error occurs setting a new active account.
    func test_handleAndRoute_didDeleteAccount_setActiveFail() async {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [alt]
        stateService.activeAccount = alt
        authRepository.setActiveAccountError = BitwardenTestError.example
        let route = await subject.handleAndRoute(.didDeleteAccount)
        XCTAssertEqual(route, .landing)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `handleAndRoute(_ :)` delivers the locked active user to `.vaultUnlock`
    ///     through  `.didLockAccount()`.
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
                didSwitchAccountAutomatically: false,
            ),
        )

        XCTAssertEqual(
            route,
            .vaultUnlock(
                active,
                animated: false,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false,
            ),
        )
    }

    /// `handleAndRoute(_ :)` handles `.didLockAccount()`
    ///     without moving the user from their current position when locking an alternate account.
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
                didSwitchAccountAutomatically: false,
            ),
        )

        XCTAssertEqual(
            route,
            .complete,
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()` to `.landing`
    /// when no user ID is passed.
    func test_handleAndRoute_didLogout_noUserID() async {
        let route = await subject.handleAndRoute(.didLogout(userId: nil, userInitiated: false))
        XCTAssertEqual(route, .landing)
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()` to `.landing`
    ///     when no accounts are present.
    func test_handleAndRoute_didLogout_automatic_alternateAccount() async {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [
            alt,
        ]
        authRepository.altAccounts = [alt]
        let route = await subject.handleAndRoute(.didLogout(userId: alt.profile.userId, userInitiated: false))
        XCTAssertEqual(route, .landing)
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()` to `.landing`
    ///     when no accounts are present.
    func test_handleAndRoute_didLogout_automatic_noAccounts() async {
        let route = await subject.handleAndRoute(.didLogout(userId: "123", userInitiated: false))
        XCTAssertEqual(route, .landing)
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()` to `.vaultUnlock`
    ///     when the current account is locked.
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
        stateService.isAuthenticated[main.profile.userId] = true

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: alt.profile.userId,
                    userInitiated: true,
                ),
            ),
        )

        XCTAssertEqual(
            route,
            .vaultUnlock(
                main,
                animated: false,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false,
            ),
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()` to `.complete`
    ///     when the current account is unlocked.
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
                    userInitiated: true,
                ),
            ),
        )

        XCTAssertEqual(
            route,
            .complete,
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()` to `.vaultUnlock`
    ///     for an alternate account when the logout is user initiated and the alt is locked.
    func test_handleAndRoute_logout_userInitiated_lockedAlt() async {
        let alt = Account.fixtureAccountLogin()
        authRepository.activeAccount = nil
        authRepository.isLockedResult = .success(true)
        authRepository.altAccounts = [
            alt,
        ]
        stateService.accounts = [
            alt,
        ]
        stateService.isAuthenticated[alt.profile.userId] = true

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: "123",
                    userInitiated: true,
                ),
            ),
        )

        XCTAssertEqual(
            route,
            .vaultUnlock(
                alt,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: true,
            ),
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()` to `.vaultUnlock`
    ///     when logging out the active account and the alt is locked.
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
        stateService.isAuthenticated[alt.profile.userId] = true

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: main.profile.userId,
                    userInitiated: true,
                ),
            ),
        )

        XCTAssertEqual(
            route,
            .vaultUnlock(
                alt,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: true,
            ),
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()` to `.complete`
    ///     when logging out the active account and the alternate is unlocked.
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
                    userInitiated: true,
                ),
            ),
        )

        XCTAssertEqual(
            route,
            .complete,
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()` to `.landing`
    ///     when no accounts are present.
    func test_handleAndRoute_didLogout_userInitiated_noAccounts() async {
        let route = await subject.handleAndRoute(.didLogout(userId: "123", userInitiated: true))
        XCTAssertEqual(route, .landing)
    }

    /// `handleAndRoute(_ :)` redirects `.lockVault()` to `.vaultUnlock`
    ///     when the active account is locked.
    func test_handleAndRoute_lock_active_success() async {
        let main = Account.fixture()
        authRepository.activeAccount = main
        authRepository.isLockedResult = .success(true)

        let route = await subject.handleAndRoute(
            .action(
                .lockVault(userId: main.profile.userId),
            ),
        )

        XCTAssertFalse(authRepository.hasManuallyLocked)

        XCTAssertEqual(
            route,
            .vaultUnlock(
                main,
                animated: false,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false,
            ),
        )
    }

    /// `handleAndRoute(_ :)` redirects `.lockVault()` to `.vaultUnlock`
    /// when the active account is locked with manual locking.
    func test_handleAndRoute_lock_active_successWithManualLocking() async {
        let main = Account.fixture()
        authRepository.activeAccount = main
        authRepository.isLockedResult = .success(true)

        let route = await subject.handleAndRoute(
            .action(
                .lockVault(userId: main.profile.userId, isManuallyLocking: true),
            ),
        )

        XCTAssertTrue(authRepository.hasManuallyLocked)

        XCTAssertEqual(
            route,
            .vaultUnlock(
                main,
                animated: false,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false,
            ),
        )
    }

    /// `handleAndRoute(_ :)` redirects `.lockVault()` to `.vaultUnlock`
    ///     when an alternate account is locked but the active is also locked.
    func test_handleAndRoute_lock_alternate_activeLocked() async {
        let main = Account.fixture()
        let alt = Account.fixtureAccountLogin()
        authRepository.activeAccount = main
        authRepository.altAccounts = [alt]
        stateService.isAuthenticated[main.profile.userId] = true

        let route = await subject.handleAndRoute(
            .action(
                .lockVault(userId: alt.profile.userId),
            ),
        )

        XCTAssertFalse(authRepository.hasManuallyLocked)

        XCTAssertEqual(
            route,
            .vaultUnlock(
                main,
                animated: false,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false,
            ),
        )
    }

    /// `handleAndRoute(_ :)` redirects `.lockVault()` to `.landing`
    ///     when there are no accounts.
    func test_handleAndRoute_lock_noAccounts() async {
        authRepository.activeAccount = nil
        authRepository.altAccounts = []

        let route = await subject.handleAndRoute(
            .action(
                .lockVault(
                    userId: Account.fixtureAccountLogin().profile.userId,
                ),
            ),
        )

        XCTAssertEqual(
            route,
            .landing,
        )
    }

    /// `handleAndRoute(_ :)` redirects `.lockVault()` to `.vaultUnlock`
    ///     when attempting to lock an unknown alternate account and the active account is locked.
    func test_handleAndRoute_lock_unknown() async {
        let main = Account.fixture()
        authRepository.activeAccount = main
        authRepository.altAccounts = []
        stateService.isAuthenticated[main.profile.userId] = true

        let route = await subject.handleAndRoute(
            .action(
                .lockVault(
                    userId: Account.fixtureAccountLogin().profile.userId,
                ),
            ),
        )

        XCTAssertEqual(
            route,
            .vaultUnlock(
                main,
                animated: false,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false,
            ),
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()` to `.vaultUnlock`
    ///     for the main account when the event is user initiated, the main is locked,
    ///     and there is no account found when requesting logout.
    func test_handleAndRoute_logout_userInitiated_notFound_locked() async {
        let main = Account.fixture()
        authRepository.activeAccount = main
        authRepository.isLockedResult = .success(true)
        authRepository.altAccounts = []
        stateService.accounts = [
            main,
        ]
        stateService.isAuthenticated[main.profile.userId] = true

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: "123",
                    userInitiated: true,
                ),
            ),
        )

        XCTAssertEqual(
            route,
            .vaultUnlock(
                main,
                animated: false,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false,
            ),
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()` to `.vaultUnlock`
    ///     when an error is thrown attempting to log out the active account.
    func test_handleAndRoute_logout_system_active_error() async {
        let main = Account.fixture()
        authRepository.activeAccount = main
        authRepository.altAccounts = []
        authRepository.logoutResult = .failure(BitwardenTestError.example)
        stateService.accounts = []
        stateService.isAuthenticated[main.profile.userId] = true

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: main.profile.userId,
                    userInitiated: false,
                ),
            ),
        )

        XCTAssertEqual(
            route,
            .vaultUnlock(
                main,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false,
            ),
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()` to `.landing`
    ///     when the event is system initiated and there is no alternate account.
    ///     System driven logouts do not trigger an account switch.
    func test_handleAndRoute_logout_system_active_noAlt() async {
        let main = Account.fixture()
        authRepository.activeAccount = main
        authRepository.altAccounts = []
        stateService.accounts = []

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: main.profile.userId,
                    userInitiated: false,
                ),
            ),
        )

        XCTAssertEqual(
            route,
            .landing,
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()` to `.landing`
    ///     when an error is thrown attempting to log out an alternate account.
    func test_handleAndRoute_logout_system_alternate_error() async {
        let alt = Account.fixture()
        authRepository.activeAccount = nil
        authRepository.altAccounts = [alt]
        authRepository.logoutResult = .failure(BitwardenTestError.example)
        stateService.accounts = [.fixture()]

        let route = await subject.handleAndRoute(
            .action(
                .logout(
                    userId: alt.profile.userId,
                    userInitiated: false,
                ),
            ),
        )

        XCTAssertEqual(
            route,
            .landing,
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()` to `.landing`
    ///     when the event is system initiated and there are no accounts.
    ///     System driven logouts do not trigger an account switch.
    func test_handleAndRoute_logout_system_noAccounts() async {
        let main = Account.fixture()
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
                    userInitiated: false,
                ),
            ),
        )

        XCTAssertEqual(
            route,
            .landing,
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didLogout()` to `.vaultUnlock`
    ///     by way of an account switch when the logout is user initiated
    ///     and a locked alternate is available.
    func test_handleAndRoute_didLogout_userInitiated_alternateAccount() {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [
            alt,
        ]
        stateService.isAuthenticated[alt.profile.userId] = true
        authRepository.altAccounts = [alt]
        var route: AuthRoute?
        let task = Task {
            route = await subject.handleAndRoute(
                .didLogout(
                    userId: "123",
                    userInitiated: true,
                ),
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
                didSwitchAccountAutomatically: true,
            ),
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didStart` to `.vaultUnlock`
    ///     when there are only locked accounts.
    func test_handleAndRoute_didStart_alternateAccount() async {
        let alt = Account.fixtureAccountLogin()
        stateService.accounts = [
            alt,
        ]
        stateService.isAuthenticated[alt.profile.userId] = true
        authRepository.altAccounts = [alt]
        let route = await subject.handleAndRoute(.didStart)
        XCTAssertEqual(
            route,
            .vaultUnlock(
                alt,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false,
            ),
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didStart` to `.introCarousel` if there's no accounts and
    /// the carousel flow is enabled.
    func test_handleAndRoute_didStart_carouselFlow() async {
        let route = await subject.handleAndRoute(.didStart)

        XCTAssertEqual(route, .introCarousel)
    }

    /// `handleAndRoute(_ :)` redirects `.didStart` to `.landing` if there's no accounts, the
    /// carousel flow is enabled, but the carousel has already been shown.
    func test_handleAndRoute_didStart_carouselFlow_carouselShown() async {
        stateService.introCarouselShown = true

        let route = await subject.handleAndRoute(.didStart)

        XCTAssertEqual(route, .landing)
    }

    /// `handleAndRoute(_ :)` redirects `.didStart` to `.landing` if it's running in an extension.
    func test_handleAndRoute_didStart_carouselFlow_extension() async {
        subject = AuthRouter(
            isInAppExtension: true,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                configService: configService,
                errorReporter: errorReporter,
                stateService: stateService,
                vaultTimeoutService: vaultTimeoutService,
            ),
        )

        let route = await subject.handleAndRoute(.didStart)

        XCTAssertEqual(route, .landing)
    }

    /// `handleAndRoute(_ :)` redirects `.didStart` to `.completeWithNeverUnlockKey` if there's an
    /// existing account with never lock enabled and sets the intro carousel as shown.
    func test_handleAndRoute_didStart_carouselFlow_existingAccountNeverLock() async {
        let account = Account.fixture()
        authRepository.activeAccount = .fixture()
        vaultTimeoutService.vaultTimeout[account.profile.userId] = .never

        let route = await subject.handleAndRoute(.didStart)

        XCTAssertEqual(route, .completeWithNeverUnlockKey)
        XCTAssertTrue(stateService.introCarouselShown)
    }

    /// `handleAndRoute(_ :)` redirects `.didStart` to `.vaultUnlock` if there's an
    /// existing account with never lock enabled on manually locked and sets the intro carousel as shown.
    @MainActor
    func test_handleAndRoute_didStart_carouselFlow_existingAccountNeverLockOnManuallylocked() async {
        let account = Account.fixture()
        authRepository.activeAccount = .fixture()
        vaultTimeoutService.vaultTimeout[account.profile.userId] = .never
        stateService.isAuthenticated[account.profile.userId] = true
        stateService.manuallyLockedAccounts[account.profile.userId] = true

        let route = await subject.handleAndRoute(.didStart)

        XCTAssertEqual(
            route,
            .vaultUnlock(
                account,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false,
            ),
        )
        XCTAssertTrue(stateService.introCarouselShown)
    }

    /// `handleAndRoute(_ :)` redirects `.didStart` to `.completeWithNeverUnlockKey` and unlocks the vault if the
    /// account never times out with a logout timeout action.
    func test_handleAndRoute_didStart_neverLockLogout() async {
        let account = Account.fixtureAccountLogin()
        authRepository.activeAccount = account
        authRepository.sessionTimeoutAction[account.profile.userId] = .logout
        vaultTimeoutService.vaultTimeout[account.profile.userId] = .never

        let route = await subject.handleAndRoute(.didStart)

        XCTAssertEqual(route, .completeWithNeverUnlockKey)
        XCTAssertTrue(authRepository.unlockVaultWithNeverlockKeyCalled)
    }

    /// `handleAndRoute(_ :)` redirects `.didStart` to `.vaultUnlock`
    ///     when the account is set to timeout on app start with a lock vault action.
    func test_handleAndRoute_didStart_timeoutOnAppRestart_lock() async {
        let active = Account.fixtureAccountLogin()
        authRepository.activeAccount = active
        stateService.isAuthenticated[active.profile.userId] = true

        vaultTimeoutService.vaultTimeout = [
            active.profile.userId: .onAppRestart,
        ]
        let route = await subject.handleAndRoute(.didStart)
        XCTAssertEqual(
            route,
            .vaultUnlock(
                active,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false,
            ),
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didStart` to `.landing` when the account has a logout
    /// timeout action. System driven logouts do not trigger an account switch.
    func test_handleAndRoute_didStart_timeoutOnAppRestart_logout() async {
        let account = Account.fixtureAccountLogin()
        authRepository.activeAccount = account
        authRepository.logoutResult = .success(())
        authRepository.sessionTimeoutAction[account.profile.userId] = .logout
        authRepository.checkSessionTimeoutsShouldTimeoutActiveUser = true

        let route = await subject.handleAndRoute(.didStart)

        XCTAssertEqual(route, .landingSoftLoggedOut(email: "user@bitwarden.com"))
        XCTAssertTrue(authRepository.logoutCalled)
        XCTAssertTrue(authRepository.checkSessionTimeoutCalled)
    }

    /// `handleAndRoute(_ :)` calls `checkSessionTimeouts()` when handling `.didStart`.
    func test_handleAndRoute_didStart_checksSessionTimeouts() async {
        let account = Account.fixture()
        authRepository.activeAccount = account
        authRepository.checkSessionTimeoutsShouldTimeoutActiveUser = false
        stateService.isAuthenticated[account.profile.userId] = true

        let route = await subject.handleAndRoute(.didStart)

        XCTAssertEqual(
            route,
            .vaultUnlock(
                account,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false,
            ),
        )
        XCTAssertTrue(authRepository.checkSessionTimeoutCalled)
        XCTAssertEqual(authRepository.checkSessionTimeoutIsAppRestart, true)
    }

    /// `handleAndRoute(_ :)` redirects `.didTimeout` to `.complete`
    ///     if the account has never lock enabled.
    func test_handleAndRoute_didTimeout_neverLock() async {
        vaultTimeoutService.vaultTimeout = [
            "123": .never,
        ]
        let route = await subject.handleAndRoute(.didTimeout(userId: "123"))
        XCTAssertEqual(route, .complete)
    }

    /// `handleAndRoute(_ :)` redirects `.didTimeout` to `.landing`
    ///     when there are no accounts.
    func test_handleAndRoute_didTimeout_noAccounts() async {
        let route = await subject.handleAndRoute(.didTimeout(userId: "123"))
        XCTAssertEqual(route, .landing)
    }

    /// `handleAndRoute(_ :)` redirects `.didTimeout` to `.vaultUnlock`
    /// if the account session has timed out and the action is lock and saves
    /// rehydration state if needed.
    func test_handleAndRoute_didTimeout_sessionExpired_lock() async {
        let account = Account.fixture()
        authRepository.activeAccount = account
        vaultTimeoutService.vaultTimeout = [
            account.profile.userId: .fiveMinutes,
        ]
        stateService.isAuthenticated[account.profile.userId] = true
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
                didSwitchAccountAutomatically: false,
            ),
        )
        XCTAssertTrue(rehydrationHelper.saveRehydrationStateIfNeededCalled)
    }

    /// `handleAndRoute(_ :)` in app extension redirects `.didTimeout` to `.vaultUnlock`
    /// if the account session has timed out and the action is lock but doesn't save
    /// rehydration state.
    func test_handleAndRoute_didTimeout_sessionExpired_lock_inAppExtension() async {
        subject = AuthRouter(
            isInAppExtension: true,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                biometricsRepository: biometricsRepository,
                configService: configService,
                errorReporter: errorReporter,
                rehydrationHelper: rehydrationHelper,
                stateService: stateService,
                vaultTimeoutService: vaultTimeoutService,
            ),
        )

        let account = Account.fixture()
        authRepository.activeAccount = account
        vaultTimeoutService.vaultTimeout = [
            account.profile.userId: .fiveMinutes,
        ]
        stateService.isAuthenticated[account.profile.userId] = true
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
                didSwitchAccountAutomatically: false,
            ),
        )
        XCTAssertFalse(rehydrationHelper.saveRehydrationStateIfNeededCalled)
    }

    /// `handleAndRoute(_ :)` redirects `.didTimeout` to `.landing`
    ///     if the account session has timed out and the action is logout.
    func test_handleAndRoute_didTimeout_sessionExpired_logout() async {
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
            .landing,
        )
    }

    /// `handleAndRoute(_ :)` redirects `.didTimeout` to `.landing`
    ///     if the account session has timed out, the action is logout,
    ///     and an error occurs.
    func test_handleAndRoute_didTimeout_sessionExpired_logout_error() async {
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
            .landing,
        )
    }

    /// `handleAndRoute(_ :)` redirects `.switchAccount()` to `.landing`
    ///     when an error occurs setting the active account.
    func test_handleAndRoute_switchAccount_error() async {
        let active = Account.fixture()
        authRepository.activeAccount = active
        authRepository.altAccounts = [.fixture(profile: .fixture(userId: "2"))]
        authRepository.isLockedResult = .success(false)
        authRepository.setActiveAccountError = BitwardenTestError.example
        let route = await subject.handleAndRoute(.action(.switchAccount(isAutomatic: true, userId: "2")))
        XCTAssertEqual(route, .landing)
    }

    /// `handleAndRoute(_ :)` redirects `.switchAccount()` to `.complete`
    ///     when that account is already active.
    func test_handleAndRoute_switchAccount_toActive() async {
        let active = Account.fixture()
        authRepository.activeAccount = active
        authRepository.isLockedResult = .success(false)
        vaultTimeoutService.lastActiveTime = [:]
        let route = await subject.handleAndRoute(
            .action(
                .switchAccount(isAutomatic: true, userId: active.profile.userId),
            ),
        )
        XCTAssertEqual(route, .complete)
        XCTAssertEqual(authRepository.setActiveAccountId, active.profile.userId)
        XCTAssertNil(vaultTimeoutService.lastActiveTime[active.profile.userId])
    }

    /// `handleAndRoute(_ :)` redirects `.switchAccount()` to `.vaultUnlock` when switching to a
    /// locked inactive account.
    func test_handleAndRoute_switchAccount_toInactive() async {
        let active = Account.fixture()
        let inactive = Account.fixture(profile: .fixture(userId: "2"))
        authRepository.activeAccount = active
        authRepository.altAccounts = [inactive]
        authRepository.isLockedResult = .success(true)
        stateService.isAuthenticated["2"] = true
        vaultTimeoutService.lastActiveTime = [:]
        let route = await subject.handleAndRoute(
            .action(
                .switchAccount(isAutomatic: true, userId: inactive.profile.userId),
            ),
        )
        XCTAssertEqual(
            route,
            .vaultUnlock(
                inactive,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: true,
            ),
        )
        XCTAssertEqual(authRepository.setActiveAccountId, inactive.profile.userId)
        XCTAssertNotNil(vaultTimeoutService.lastActiveTime[active.profile.userId])
    }

    /// `handleAndRoute(_ :)` redirects `.switchAccount()` to `.landingSoftLoggedOut` when that
    /// account is soft logged out.
    func test_handleAndRoute_switchAccount_softLoggedOutAccount() async {
        let account = Account.fixture()
        authRepository.activeAccount = account
        authRepository.isLockedResult = .success(true)
        stateService.isAuthenticated[account.profile.userId] = false

        let route = await subject.handleAndRoute(
            .action(
                .switchAccount(isAutomatic: true, userId: account.profile.userId),
            ),
        )
        XCTAssertEqual(route, .landingSoftLoggedOut(email: account.profile.email))
        XCTAssertEqual(authRepository.setActiveAccountId, account.profile.userId)
    }
}
