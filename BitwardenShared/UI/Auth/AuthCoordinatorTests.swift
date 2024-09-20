import AuthenticationServices
import SwiftUI
import XCTest

// swiftlint:disable file_length

@testable import BitwardenShared

// MARK: - AuthCoordinatorTests

class AuthCoordinatorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var authDelegate: MockAuthDelegate!
    var authRepository: MockAuthRepository!
    var authService: MockAuthService!
    var authRouter: AuthRouter!
    var errorReporter: MockErrorReporter!
    var rootNavigator: MockRootNavigator!
    var stackNavigator: MockStackNavigator!
    var stateService: MockStateService!
    var subject: AuthCoordinator!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        appSettingsStore = MockAppSettingsStore()
        authDelegate = MockAuthDelegate()
        authRepository = MockAuthRepository()
        authService = MockAuthService()
        errorReporter = MockErrorReporter()
        rootNavigator = MockRootNavigator()
        stackNavigator = MockStackNavigator()
        stateService = MockStateService()
        vaultTimeoutService = MockVaultTimeoutService()
        let services = ServiceContainer.withMocks(
            appSettingsStore: appSettingsStore,
            authRepository: authRepository,
            authService: authService,
            errorReporter: errorReporter,
            stateService: stateService,
            vaultTimeoutService: vaultTimeoutService
        )
        authRouter = AuthRouter(
            isInAppExtension: false,
            services: services
        )
        subject = AuthCoordinator(
            appExtensionDelegate: MockAppExtensionDelegate(),
            delegate: authDelegate,
            rootNavigator: rootNavigator,
            router: authRouter.asAnyRouter(),
            services: services,
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()
        appSettingsStore = nil
        authDelegate = nil
        authRepository = nil
        authService = nil
        errorReporter = nil
        rootNavigator = nil
        stackNavigator = nil
        stateService = nil
        vaultTimeoutService = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.complete` notifies the delegate that auth has completed.
    @MainActor
    func test_navigate_complete() {
        subject.navigate(to: .complete)
        XCTAssertTrue(authDelegate.didCompleteAuthCalled)
    }

    /// `navigate(to:)` with `.complete` dismisses a presented view and notifies the delegate that
    /// auth has completed.
    @MainActor
    func test_navigate_complete_withPresented() {
        subject.navigate(to: .updateMasterPassword)
        subject.navigate(to: .complete)
        XCTAssertTrue(authDelegate.didCompleteAuthCalled)
        XCTAssertEqual(stackNavigator.actions.last?.type, .dismissedWithCompletionHandler)
    }

    /// `navigate(to:)` with `.checkEmail` pushes the check email view onto the stack navigator.
    @MainActor
    func test_navigate_checkEmail() throws {
        subject.navigate(to: .checkEmail(email: "email@example.com"))

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<CheckEmailView>)
    }

    /// `navigate(to:)` with `.completeWithNeverUnlockKey` notifies the delegate that auth has completed.
    @MainActor
    func test_navigate_completeWithNeverUnlockKey() {
        subject.navigate(to: .completeWithNeverUnlockKey)
        XCTAssertTrue(authDelegate.didCompleteAuthCalled)
    }

    /// `navigate(to:)` with `.createAccount` pushes the create account view onto the stack navigator.
    @MainActor
    func test_navigate_createAccount() throws {
        subject.navigate(to: .createAccount)

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<CreateAccountView>)
    }

    /// `navigate(to:)` with `.completeRegistration` pushes the create account view onto the stack navigator.
    @MainActor
    func test_navigate_completeRegistration() throws {
        subject.navigate(to: .completeRegistration(
            emailVerificationToken: "thisisanamazingtoken",
            userEmail: "email@example.com"
        ))

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<CompleteRegistrationView>)
    }

    /// `navigate(to:)` with `.completeRegistrationFromAppLink` pushes the create account view onto the stack navigator.
    @MainActor
    func test_navigate_completeRegistrationFromAppLink() throws {
        subject.navigate(to: .completeRegistrationFromAppLink(
            emailVerificationToken: "thisisanamazingtoken",
            userEmail: "email@example.com",
            fromEmail: true
        ))

        let landingAction = try XCTUnwrap(stackNavigator.actions[1])
        let completeRegistrationAction = try XCTUnwrap(stackNavigator.actions[2])
        let completeRegistrationNavigationController = try XCTUnwrap(
            completeRegistrationAction.view as? UINavigationController
        )
        let lastAction = try XCTUnwrap(stackNavigator.actions.last)

        XCTAssertTrue(
            completeRegistrationNavigationController.viewControllers.first
                is UIHostingController<CompleteRegistrationView>
        )
        XCTAssertTrue(landingAction.view is LandingView)
        XCTAssertEqual(lastAction.type, .dismissedWithCompletionHandler)
    }

    /// `navigate(to:)` with `.startRegistration` pushes the start registration view onto the stack navigator.
    @MainActor
    func test_navigate_startRegistration() throws {
        subject.navigate(to: .startRegistration, context: MockStartRegistrationDelegate())

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<StartRegistrationView>)
    }

    /// `navigate(to:)` with `.startRegistrationFromExpiredLink` pushes the start registration view
    /// onto the stack navigator from expired link.
    @MainActor
    func test_navigate_startRegistrationFromExpiredLink() throws {
        subject.navigate(to: .completeRegistrationFromAppLink(
            emailVerificationToken: "thisisanamazingtoken",
            userEmail: "email@example.com",
            fromEmail: true
        ))
        subject.navigate(to: .expiredLink)
        subject.navigate(to: .startRegistrationFromExpiredLink)

        let landingAction = try XCTUnwrap(stackNavigator.actions[5])
        let startRegistration = try XCTUnwrap(stackNavigator.actions[6])
        let startRegistrationNavigationController = try XCTUnwrap(
            startRegistration.view as? UINavigationController
        )
        let lastAction = try XCTUnwrap(stackNavigator.actions.last)

        XCTAssertTrue(
            startRegistrationNavigationController.viewControllers.first
                is UIHostingController<StartRegistrationView>
        )
        XCTAssertTrue(landingAction.view is LandingView)
        XCTAssertEqual(landingAction.type, .replaced)
        XCTAssertEqual(lastAction.type, .dismissedWithCompletionHandler)
    }

    /// `navigate(to:)` with `.dismiss` dismisses all presented view.
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .createAccount)
        subject.navigate(to: .dismiss)
        let lastAction = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(lastAction.type, .dismissed)
    }

    /// `navigate(to:)` with `.dismissPresented` dismisses the presented view.
    @MainActor
    func test_navigate_dismissPresented() throws {
        subject.navigate(to: .checkEmail(email: "email@example.com"))
        subject.navigate(to: .dismissPresented)
        let lastAction = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(lastAction.type, .presented)
    }

    /// `navigate(to:)` with `.dismissWithAction` dismisses the presented view.
    @MainActor
    func test_navigate_dismissWithAction() throws {
        var didRun = false
        subject.navigate(to: .dismissWithAction(DismissAction(action: { didRun = true })))
        let lastAction = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(lastAction.type, .dismissedWithCompletionHandler)
        XCTAssertTrue(didRun)
    }

    /// `navigate(to:)` with `.expiredLink` pushes the expired link view onto the stack navigator.
    @MainActor
    func test_navigate_expiredLink() throws {
        subject.navigate(to: .expiredLink)

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<ExpiredLinkView>)
    }

    /// `navigate(to:)` with `.enterpriseSingleSignOn` pushes the enterprise single sign-on view onto the stack
    /// navigator.
    @MainActor
    func test_navigate_enterpriseSingleSignOn() throws {
        subject.navigate(to: .enterpriseSingleSignOn(email: "email@example.com"))

        XCTAssertEqual(stackNavigator.actions.last?.type, .presented)
        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<SingleSignOnView>)
    }

    /// `navigate(to:)` with `.introCarousel` replaces the navigation stack with the intro carousel.
    @MainActor
    func test_navigate_introCarousel() {
        subject.navigate(to: .introCarousel)

        XCTAssertTrue(stackNavigator.actions.last?.view is IntroCarouselView)
        XCTAssertEqual(stackNavigator.actions.last?.type, .replaced)
        XCTAssertTrue(stackNavigator.isNavigationBarHidden)
    }

    /// `navigate(to:)` with `.landing` pushes the landing view onto the stack navigator.
    @MainActor
    func test_navigate_landing() {
        subject.navigate(to: .landing)
        XCTAssertTrue(stackNavigator.actions.last?.view is LandingView)
    }

    /// `navigate(to:)` with `.landing` from `.login` pops back to the landing view.
    @MainActor
    func test_navigate_landing_fromLogin() {
        stackNavigator.viewControllersToPop = [
            UIViewController(),
        ]
        subject.navigate(to: .landing)

        XCTAssertEqual(stackNavigator.actions.last?.type, .poppedToRoot)
    }

    /// `navigate(to:)` with `.landingSoftLoggedOut` pushes the landing view onto the stack
    /// navigator and populates the email field.
    @MainActor
    func test_navigate_landingSoftLoggedOut() throws {
        subject.navigate(to: .landingSoftLoggedOut(email: "user@bitwarden.com"))
        XCTAssertTrue(stackNavigator.actions.last?.view is LandingView)

        let view = try XCTUnwrap(stackNavigator.actions.last?.view as? LandingView)
        XCTAssertEqual(view.store.state.email, "user@bitwarden.com")
    }

    /// `navigate(to:)` with `.login` pushes the login view onto the stack navigator and hides the back button.
    @MainActor
    func test_navigate_login() throws {
        appSettingsStore.preAuthEnvironmentUrls = EnvironmentUrlData.defaultEU
        subject.navigate(to: .login(username: "username"))

        XCTAssertEqual(stackNavigator.actions.last?.type, .pushed)
        let viewController = try XCTUnwrap(
            stackNavigator.actions.last?.view as? UIHostingController<LoginView>
        )
        XCTAssertTrue(viewController.navigationItem.hidesBackButton)

        let view = viewController.rootView
        let state = view.store.state
        XCTAssertEqual(state.username, "username")
        XCTAssertEqual(state.serverURLString, "vault.bitwarden.eu")
    }

    /// `navigate(to:)` with `.login` pushes the login view onto the stack navigator and hides the back button.
    @MainActor
    func test_navigate_login_newAccount() throws {
        appSettingsStore.preAuthEnvironmentUrls = EnvironmentUrlData.defaultEU
        subject.navigate(to: .login(username: "username", isNewAccount: true))

        XCTAssertEqual(stackNavigator.actions.last?.type, .pushed)
        let viewController = try XCTUnwrap(
            stackNavigator.actions.last?.view as? UIHostingController<LoginView>
        )
        XCTAssertTrue(viewController.navigationItem.hidesBackButton)

        let view = viewController.rootView
        let state = view.store.state
        XCTAssertTrue(state.isNewAccount)
        XCTAssertEqual(state.username, "username")
        XCTAssertEqual(state.serverURLString, "vault.bitwarden.eu")
    }

    /// `navigate(to:)` with `.login`, when using a self-hosted environment,
    /// pushes the login view onto the stack navigator and hides the back button.
    /// It also initializes `LoginState` with the self-hosted URL host.
    @MainActor
    func test_navigate_login_selfHosted() async throws {
        appSettingsStore.preAuthEnvironmentUrls = EnvironmentUrlData(webVault: URL(string: "http://www.example.com")!)
        subject.navigate(to: .login(username: "username"))

        let viewController = try XCTUnwrap(
            stackNavigator.actions.last?.view as? UIHostingController<LoginView>
        )
        let view = viewController.rootView
        let state = view.store.state
        XCTAssertEqual(state.username, "username")
        XCTAssertEqual(state.serverURLString, "www.example.com")
    }

    /// `navigate(to:)` with `.loginWithDevice` pushes the login with device view onto the stack navigator.
    @MainActor
    func test_navigate_loginWithDevice() throws {
        subject.navigate(to: .loginWithDevice(
            email: "example@email.com",
            authRequestType: AuthRequestType.authenticateAndUnlock,
            isAuthenticated: false
        ))

        XCTAssertEqual(stackNavigator.actions.last?.type, .presented)
        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<LoginWithDeviceView>)
    }

    /// `navigate(to:)` with `.masterPasswordHint` presents the master password hint view.
    @MainActor
    func test_navigate_masterPasswordHint() throws {
        subject.navigate(to: .masterPasswordHint(username: "email@example.com"))

        XCTAssertEqual(stackNavigator.actions.last?.type, .presented)
        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<PasswordHintView>)
    }

    /// `navigate(to:)` with `.preventAccountLock` presents the prevent account lock view.
    @MainActor
    func test_navigate_preventAccountLock() throws {
        subject.navigate(to: .masterPasswordGuidance)

        XCTAssertEqual(stackNavigator.actions.last?.type, .presented)
        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<MasterPasswordGuidanceView>)
    }

    /// `navigate(to:)` with `.selfHosted` pushes the self-hosted view onto the stack navigator.
    @MainActor
    func test_navigate_selfHosted() throws {
        subject.navigate(to: .selfHosted(currentRegion: .unitedStates))

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<SelfHostedView>)
    }

    /// `navigate(to:)` with `.removeMasterPassword` pushes the remove master password view onto the stack navigator.
    @MainActor
    func test_navigate_removeMasterPassword() throws {
        subject.navigate(to: .removeMasterPassword(organizationName: "Example Org"))

        XCTAssertTrue(stackNavigator.actions.last?.view is RemoveMasterPasswordView)
        XCTAssertEqual(stackNavigator.actions.last?.type, .pushed)
    }

    /// `navigate(to:)` with `.setMasterPassword` pushes the set master password view onto the stack navigator.
    @MainActor
    func test_navigate_setMasterPassword() throws {
        subject.navigate(to: .setMasterPassword(organizationIdentifier: "ORG_ID"))

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<SetMasterPasswordView>)
    }

    /// `handleEvent()` with `.switchAccount` with an locked account navigates to vault unlock
    @MainActor
    func test_navigate_switchAccount_locked() {
        let account = Account.fixture()
        authRepository.altAccounts = [account]
        vaultTimeoutService.isClientLocked[account.profile.userId] = true
        stateService.activeAccount = account
        stateService.isAuthenticated[account.profile.userId] = true

        let task = Task {
            await subject.handleEvent(.action(.switchAccount(isAutomatic: true, userId: account.profile.userId)))
        }
        waitFor(stackNavigator.actions.last?.type == .replaced)
        task.cancel()
        XCTAssertTrue(stackNavigator.actions.last?.view is VaultUnlockView)
    }

    /// `navigate(to:)` with `.switchAccount` with an unlocked account triggers completion
    @MainActor
    func test_navigate_switchAccount_unlocked() {
        let account = Account.fixture()
        authRepository.altAccounts = [account]
        authRepository.isLockedResult = .success(false)
        authRepository.unlockVaultWithNeverlockResult = .success(())
        stateService.activeAccount = account

        let task = Task {
            await subject.handleEvent(.action(.switchAccount(isAutomatic: true, userId: account.profile.userId)))
        }
        waitFor(authDelegate.didCompleteAuthCalled)
        task.cancel()

        XCTAssertTrue(authDelegate.didCompleteAuthCalled)
    }

    /// `navigate(to:)` with `.switchAccount` with an unknown lock status account navigates to vault unlock.
    @MainActor
    func test_navigate_switchAccount_unknownLock() {
        let account = Account.fixture()
        authRepository.altAccounts = [account]
        authRepository.isLockedResult = .failure(VaultTimeoutServiceError.noAccountFound)
        stateService.activeAccount = account
        stateService.isAuthenticated[account.profile.userId] = true

        let task = Task {
            await subject.handleEvent(.action(.switchAccount(isAutomatic: true, userId: account.profile.userId)))
        }
        waitFor(stackNavigator.actions.last?.view is VaultUnlockView)
        task.cancel()
        XCTAssertTrue(stackNavigator.actions.last?.view is VaultUnlockView)
    }

    /// `navigate(to:)` with `.switchAccount` with an invalid account navigates to landing view.
    @MainActor
    func test_navigate_switchAccount_notFound() {
        let account = Account.fixture()
        let task = Task {
            await subject.handleEvent(.action(.switchAccount(isAutomatic: true, userId: account.profile.userId)))
        }
        waitFor(stackNavigator.actions.last?.view is LandingView)
        task.cancel()
        XCTAssertTrue(stackNavigator.actions.last?.view is LandingView)
    }

    /// `navigate(to:)` with `.twoFactor` shows the two factor auth view.
    @MainActor
    func test_navigate_twoFactor() throws {
        subject.navigate(to: .twoFactor("", .password(""), AuthMethodsData.fixture(), nil))

        XCTAssertEqual(stackNavigator.actions.last?.type, .presented)
        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<TwoFactorAuthView>)
    }

    /// `navigate(to:)` with `.updateMasterPassword` pushes the update master password view onto the stack navigator.
    @MainActor
    func test_navigate_updateMasterPassword() throws {
        subject.navigate(to: .updateMasterPassword)

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<UpdateMasterPasswordView>)
    }

    /// `navigate(to:)` with `.vaultUnlock` replaces the current view with the vault unlock view.
    @MainActor
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
    @MainActor
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

    /// `navigate(to:)` with `.vaultUnlockSetup` pushes the vault unlock setup onto the navigation stack.
    @MainActor
    func test_navigate_vaultUnlockSetup() throws {
        subject.navigate(to: .vaultUnlockSetup)

        XCTAssertEqual(stackNavigator.actions.last?.type, .replaced)
        XCTAssertTrue(stackNavigator.actions.last?.view is VaultUnlockSetupView)
    }

    /// `navigate(to:)` with `.showLoginDecryptionOptions` replaces the current view with
    /// the show decryption options view.
    @MainActor
    func test_navigate_showLoginDecryptionOptions() throws {
        subject.navigate(to: .showLoginDecryptionOptions(organizationIdentifier: "Bitwarden"))

        XCTAssertEqual(stackNavigator.actions.last?.type, .pushed)
        let viewController = try XCTUnwrap(
            stackNavigator.actions.last?.view as? UIHostingController<LoginDecryptionOptionsView>
        )
        XCTAssertTrue(viewController.navigationItem.hidesBackButton)

        let view = viewController.rootView
        let state = view.store.state
        XCTAssertEqual(state.orgIdentifier, "Bitwarden")
    }

    /// `navigate(to:)` with `.webAuthnSelfHosted` opens the WebAuthn connector web page.
    @MainActor
    func test_navigate_webAuthnSelfHosted() throws {
        let delegate = MockWebAuthnFlowDelegate()

        subject.navigate(to: .webAuthnSelfHosted(URL.example), context: delegate)

        guard let mockSession = authService.webAuthenticationSession as? MockWebAuthenticationSession else {
            XCTFail("Did not initialize web authentication session")
            return
        }

        let expectedToken = "token"
        let callbackUrl = URL(string: "https://www.example.com/?data=\(expectedToken)")

        XCTAssertTrue(mockSession.startCalled)

        XCTAssertEqual(mockSession.initUrl, URL.example)
        XCTAssertEqual(mockSession.initCallbackURLScheme, authService.callbackUrlScheme)

        mockSession.initCompletionHandler(callbackUrl, nil)

        XCTAssertEqual(delegate.completedToken, expectedToken)
    }

    /// `navigate(to:)` with `.webAuthnSelfHosted` handles errors.
    @MainActor
    func test_navigate_webAuthnSelfHosted_error() throws {
        let delegate = MockWebAuthnFlowDelegate()

        subject.navigate(to: .webAuthnSelfHosted(URL.example), context: delegate)

        guard let mockSession = authService.webAuthenticationSession as? MockWebAuthenticationSession else {
            XCTFail("Did not initialize web authentication session")
            return
        }

        XCTAssertTrue(mockSession.startCalled)

        XCTAssertEqual(mockSession.initUrl, URL.example)
        XCTAssertEqual(mockSession.initCallbackURLScheme, authService.callbackUrlScheme)

        mockSession.initCompletionHandler(nil, BitwardenTestError.example)

        XCTAssertEqual(delegate.erroredError as? BitwardenTestError, BitwardenTestError.example)
    }

    /// `navigate(to:)` with `.webAuthnSelfHosted` handles when the server sends unparseable credentials
    @MainActor
    func test_navigate_webAuthnSelfHosted_unableToDecode() throws {
        let delegate = MockWebAuthnFlowDelegate()

        subject.navigate(to: .webAuthnSelfHosted(URL.example), context: delegate)

        guard let mockSession = authService.webAuthenticationSession as? MockWebAuthenticationSession else {
            XCTFail("Did not initialize web authentication session")
            return
        }

        XCTAssertTrue(mockSession.startCalled)

        XCTAssertEqual(mockSession.initUrl, URL.example)
        XCTAssertEqual(mockSession.initCallbackURLScheme, authService.callbackUrlScheme)

        mockSession.initCompletionHandler(nil, nil)
        XCTAssertEqual(delegate.erroredError as? WebAuthnError, WebAuthnError.unableToDecodeCredential)
        delegate.erroredError = nil

        mockSession.initCompletionHandler(URL(string: "https://www.example.com/junk"), nil)
        XCTAssertEqual(delegate.erroredError as? WebAuthnError, WebAuthnError.unableToDecodeCredential)
        delegate.erroredError = nil

        mockSession.initCompletionHandler(URL(string: "https://www.example.com/?junk=token"), nil)
        XCTAssertEqual(delegate.erroredError as? WebAuthnError, WebAuthnError.unableToDecodeCredential)
    }

    /// `rootNavigator` uses a weak reference and does not retain a value once the root navigator has been erased.
    @MainActor
    func test_rootNavigator_resetWeakReference() {
        var rootNavigator: MockRootNavigator? = MockRootNavigator()
        subject = AuthCoordinator(
            appExtensionDelegate: MockAppExtensionDelegate(),
            delegate: authDelegate,
            rootNavigator: rootNavigator!,
            router: MockRouter(routeForEvent: { _ in .landing }).asAnyRouter(),
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
        )
        XCTAssertNotNil(subject.rootNavigator)

        rootNavigator = nil
        XCTAssertNil(subject.rootNavigator)
    }

    /// `showLoadingOverlay()` and `hideLoadingOverlay()` can be used to show and hide the loading overlay.
    @MainActor
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
    @MainActor
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
