import AuthenticationServices
import OSLog
import SwiftUI
import UIKit

// MARK: - AuthCoordinatorDelegate

/// An object that is signaled when specific circumstances in the auth flow have been encountered.
///
@MainActor
protocol AuthCoordinatorDelegate: AnyObject {
    /// Called when the auth flow has been completed.
    ///
    func didCompleteAuth()
}

// MARK: - AuthCoordinator

/// A coordinator that manages navigation in the authentication flow.
///
final class AuthCoordinator: NSObject, Coordinator, HasStackNavigator { // swiftlint:disable:this type_body_length
    // MARK: Types

    typealias Services = HasAccountAPIService
        & HasAppIdService
        & HasAppSettingsStore
        & HasAuthAPIService
        & HasAuthRepository
        & HasAuthService
        & HasBiometricsService
        & HasCaptchaService
        & HasClientAuth
        & HasDeviceAPIService
        & HasEnvironmentService
        & HasErrorReporter
        & HasStateService
        & HasSystemDevice
        & HasVaultTimeoutService

    // MARK: Properties

    /// A delegate used to communicate with the app extension. This should be passed to any
    /// processors that need to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    /// The delegate for this coordinator. Used to signal when auth has been completed. This should
    /// be used by the coordinator to communicate to its parent coordinator when auth completes and
    /// the auth flow should be dismissed.
    private weak var delegate: (any AuthCoordinatorDelegate)?

    /// The root navigator used to display this coordinator's interface.
    weak var rootNavigator: (any RootNavigator)?

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    var stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `AuthCoordinator`.
    ///
    /// - Parameters:
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - delegate: The delegate for this coordinator. Used to signal when auth has been completed.
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        appExtensionDelegate: AppExtensionDelegate?,
        delegate: AuthCoordinatorDelegate,
        rootNavigator: RootNavigator,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.appExtensionDelegate = appExtensionDelegate
        self.delegate = delegate
        self.rootNavigator = rootNavigator
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: AuthRoute, context: AnyObject?) { // swiftlint:disable:this function_body_length
        switch route {
        case let .alert(alert):
            showAlert(alert)
        case let .captcha(url, callbackUrlScheme):
            showCaptcha(
                url: url,
                callbackUrlScheme: callbackUrlScheme,
                delegate: context as? CaptchaFlowDelegate
            )
        case .complete:
            delegate?.didCompleteAuth()
        case .createAccount:
            showCreateAccount()
        case .dismiss:
            stackNavigator.dismiss()
        case let .enterpriseSingleSignOn(email):
            showEnterpriseSingleSignOn(email: email)
        case .landing:
            showLanding()
        case let .login(username, region, isLoginWithDeviceVisible):
            showLogin(
                state: LoginState(
                    isLoginWithDeviceVisible: isLoginWithDeviceVisible,
                    username: username,
                    region: region
                )
            )
        case .loginOptions:
            showLoginOptions()
        case let .loginWithDevice(email):
            showLoginWithDevice(email: email)
        case let .masterPasswordHint(username):
            showMasterPasswordHint(for: username)
        case .selfHosted:
            showSelfHostedView(delegate: context as? SelfHostedProcessorDelegate)
        case let .singleSignOn(callbackUrlScheme, state, url):
            showSingleSignOn(
                callbackUrlScheme: callbackUrlScheme,
                delegate: context as? SingleSignOnFlowDelegate,
                state: state,
                url: url
            )
        case let .twoFactor(email, password, authMethodsData):
            showTwoFactorAuth(email: email, password: password, authMethodsData: authMethodsData)
        case let .vaultUnlock(
            account,
            animated,
            attemptAutomaticBiometricUnlock,
            didSwitch
        ):
            showVaultUnlock(
                account: account,
                animated: animated,
                attemptAutmaticBiometricUnlock: attemptAutomaticBiometricUnlock,
                didSwitchAccountAutomatically: didSwitch
            )
        case .didDeleteAccount,
             .didLogout,
             .didStart,
             .didTimeout,
             .switchAccount:
            Task {
                await navigate(
                    asyncTo: route,
                    withRedirect: true,
                    context: context
                )
            }
        }
    }

    func navigate(
        asyncTo route: AuthRoute,
        withRedirect: Bool,
        context: AnyObject?
    ) async {
        var updatedRoute = route
        if withRedirect {
            updatedRoute = await prepareAndRedirect(route)
        }
        navigate(to: updatedRoute, context: context)
        if route == .didDeleteAccount {
            navigate(to: .alert(Alert.accountDeletedAlert()), context: context)
        }
    }

    func prepareAndRedirect(_ route: AuthRoute) async -> AuthRoute {
        switch route {
        case .didDeleteAccount:
            return await deleteAccountRedirect()
        case let .didLogout(userInitiated):
            return await logoutRedirect(userInitiated: userInitiated)
        case .didStart:
            // Go to the initial auth route redirect.
            return await preparedStartRoute()
        case let .didTimeout(userId):
            return await timeoutRedirect(userId: userId)
        case let .switchAccount(isUserInitiated, userId):
            return await switchAccountRedirect(
                isUserInitiated: isUserInitiated,
                userId: userId
            )
        case let .vaultUnlock(
            activeAccount,
            animated,
            attemptAutomaticBiometricUnlock,
            didSwitchAccountAutomatically
        ):
            return await vaultUnlockRedirect(
                activeAccount,
                animated: animated,
                attemptAutomaticBiometricUnlock: attemptAutomaticBiometricUnlock,
                didSwitchAccountAutomatically: didSwitchAccountAutomatically
            )
        case .alert,
             .captcha,
             .complete,
             .createAccount,
             .dismiss,
             .enterpriseSingleSignOn,
             .landing,
             .login,
             .loginOptions,
             .loginWithDevice,
             .masterPasswordHint,
             .selfHosted,
             .singleSignOn,
             .twoFactor:
            return route
        }
    }

    func start() {
        rootNavigator?.show(child: stackNavigator)
    }

    // MARK: Private Methods

    /// Configures the app with an active account
    ///
    private func configureActiveAccount(shouldSwitchAutomatically: Bool) async throws -> Account {
        if let active = try? await services.stateService.getActiveAccount() {
            return active
        }
        guard shouldSwitchAutomatically,
              let alternate = try await services.stateService.getAccounts().first else {
            throw StateServiceError.noActiveAccount
        }
        return try await services.authRepository.setActiveAccount(userId: alternate.profile.userId)
    }

    private func deleteAccountRedirect() async -> AuthRoute {
        let oldActiveId = try? await services.stateService.getActiveAccountId()
        guard let activeAccount = try? await configureActiveAccount(shouldSwitchAutomatically: true) else {
            return .landing
        }
        // Get the redirect for this route
        let redirect = AuthRoute.vaultUnlock(
            activeAccount,
            animated: false,
            attemptAutomaticBiometricUnlock: true,
            didSwitchAccountAutomatically: oldActiveId != activeAccount.profile.userId
        )
        // Recursively handle any subsequent redirects.
        return await prepareAndRedirect(redirect)
    }

    private func logoutRedirect(userInitiated: Bool) async -> AuthRoute {
        let oldActiveId = try? await services.stateService.getActiveAccountId()
        guard let activeAccount = try? await configureActiveAccount(shouldSwitchAutomatically: userInitiated) else {
            return .landing
        }
        let vaultUnlock = AuthRoute.vaultUnlock(
            activeAccount,
            animated: false,
            attemptAutomaticBiometricUnlock: true,
            didSwitchAccountAutomatically: oldActiveId != activeAccount.profile.userId
        )
        return await prepareAndRedirect(vaultUnlock)
    }

    private func preparedStartRoute() async -> AuthRoute {
        guard let activeAccount = try? await configureActiveAccount(shouldSwitchAutomatically: true) else {
            // If no account can be set to active, go to the landing screen.
            return .landing
        }
        // Check for the `onAppRestart` timeout condition.
        let vaultTimeout = try? await services.vaultTimeoutService
            .sessionTimeoutValue(userId: activeAccount.profile.userId)
        if vaultTimeout == .onAppRestart {
            return await prepareAndRedirect(.didTimeout(userId: activeAccount.profile.userId))
        }
        let vaultUnlock = AuthRoute.vaultUnlock(
            activeAccount,
            animated: false,
            attemptAutomaticBiometricUnlock: true,
            didSwitchAccountAutomatically: false
        )

        // Redirect the vault unlock screen if needed.
        return await prepareAndRedirect(vaultUnlock)
    }

    private func timeoutRedirect(userId: String) async -> Route {
        do {
            // Ensure the timeout interval isn't `.never`.
            let vaultTimeoutInterval = try await services.vaultTimeoutService.sessionTimeoutValue(userId: userId)
            guard vaultTimeoutInterval != .never,
                  let action = try? await services.stateService.getTimeoutAction(userId: userId) else {
                return .didTimeout(userId: userId)
            }

            switch action {
            case .lock:
                // If there is a timeout and the user has a lock vault action,
                //  return `.vaultUnlock`.
                await services.authRepository.lockVault(userId: userId)
                guard let activeAccount = try? await services.stateService.getActiveAccount(),
                      activeAccount.profile.userId == userId else {
                    return .didTimeout(userId: userId)
                }
                let vaultUnlock = AuthRoute.vaultUnlock(
                    activeAccount,
                    animated: false,
                    attemptAutomaticBiometricUnlock: true,
                    didSwitchAccountAutomatically: false
                )
                // Redirect the vault unlock
                return await prepareAndRedirect(vaultUnlock)
            case .logout:
                // If there is a timeout and the user has a logout vault action,
                //  log out the user.
                try await services.authRepository.logout(userId: userId)

                // Go to landing.
                return .landing
            }
        } catch {
            services.errorReporter.log(error: error)
            // Go to landing.
            return .landing
        }
    }

    /// Shows the captcha screen.
    ///
    /// - Parameters:
    ///   - url: The URL for the captcha screen.
    ///   - callbackUrlScheme: The callback url scheme for this application.
    ///   - delegate: A `CaptchaFlowDelegate` object that is notified when the captcha flow succeeds or fails.
    ///
    private func showCaptcha(
        url: URL,
        callbackUrlScheme: String,
        delegate: CaptchaFlowDelegate?
    ) {
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackUrlScheme
        ) { url, error in
            if let url,
               let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItem = components.queryItems?.first(where: { $0.name == "token" }),
               let token = queryItem.value {
                delegate?.captchaCompleted(token: token)
            } else if let error {
                delegate?.captchaErrored(error: error)
            }
        }

        // prefersEphemeralWebBrowserSession should be false to allow access to the hCaptcha accessibility
        // cookie set in the default browser: https://www.hcaptcha.com/accessibility
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = self
        session.start()
    }

    /// Shows the create account screen.
    private func showCreateAccount() {
        let view = CreateAccountView(
            store: Store(
                processor: CreateAccountProcessor(
                    coordinator: asAnyCoordinator(),
                    services: services,
                    state: CreateAccountState()
                )
            )
        )
        let navController = UINavigationController(rootViewController: UIHostingController(rootView: view))
        stackNavigator.present(navController)
    }

    /// Shows the enterprise single sign-on screen.
    ///
    /// - Parameter email: The user's email address.
    ///
    private func showEnterpriseSingleSignOn(email: String) {
        let processor = SingleSignOnProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: SingleSignOnState(email: email)
        )
        let store = Store(processor: processor)
        let view = SingleSignOnView(store: store)
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        stackNavigator.present(navigationController)
    }

    /// Shows the landing screen.
    ///
    private func showLanding(animated: Bool = false) {
        if stackNavigator.popToRoot(animated: UI.animated).isEmpty {
            let processor = LandingProcessor(
                coordinator: asAnyCoordinator(),
                services: services,
                state: LandingState()
            )
            let store = Store(processor: processor)
            let view = LandingView(store: store)
            stackNavigator.replace(view, animated: animated)
        }
    }

    /// Shows the login screen. If the create account flow is being presented it will be dismissed
    /// and the login screen will be pushed
    ///
    /// - Parameter state: The `LoginState` to initialize the login screen with.
    ///
    private func showLogin(state: LoginState) {
        let isPresenting = stackNavigator.rootViewController?.presentedViewController != nil

        let processor = LoginProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: state
        )
        let store = Store(processor: processor)
        let view = LoginView(store: store)
        let viewController = UIHostingController(rootView: view)

        // When hiding the back button, we need to use both SwiftUI's method alongside UIKit's, otherwise the
        // back button might flash on screen while the screen is being pushed.
        viewController.navigationItem.hidesBackButton = true
        stackNavigator.push(viewController)

        if isPresenting {
            stackNavigator.dismiss()
        }
    }

    /// Shows the login options screen.
    private func showLoginOptions() {
        let view = Text("Login Options")
        stackNavigator.push(view)
    }

    /// Shows the login with device screen.
    ///
    /// - Parameter email: The user's email.
    ///
    private func showLoginWithDevice(email: String) {
        let processor = LoginWithDeviceProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: LoginWithDeviceState(email: email)
        )
        let store = Store(processor: processor)
        let view = LoginWithDeviceView(store: store)
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        stackNavigator.present(navigationController)
    }

    /// Shows the master password hint screen for the provided username.
    ///
    /// - Parameter username: The username to get the password hint for.
    ///
    private func showMasterPasswordHint(for username: String) {
        let processor = PasswordHintProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: PasswordHintState(emailAddress: username)
        )
        let store = Store(processor: processor)
        let view = PasswordHintView(store: store)
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        stackNavigator.present(navigationController)
    }

    /// Shows the self-hosted settings view.
    private func showSelfHostedView(delegate: SelfHostedProcessorDelegate?) {
        let processor = SelfHostedProcessor(
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            state: SelfHostedState()
        )
        let view = SelfHostedView(store: Store(processor: processor))
        let navController = UINavigationController(rootViewController: UIHostingController(rootView: view))
        stackNavigator.present(navController)
    }

    /// Shows the single sign on screen.
    ///
    /// - Parameters:
    ///   - callbackUrlScheme: The callback url scheme for this application.
    ///   - delegate: A `SingleSignOnFlowDelegate` object that is notified when the single sign on flow succeeds or
    ///     fails.
    ///   - state: The password that the response has to match.
    ///   - url: The URL for the single sign on web auth session.
    ///
    private func showSingleSignOn(
        callbackUrlScheme: String,
        delegate: SingleSignOnFlowDelegate?,
        state: String,
        url: URL
    ) {
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackUrlScheme
        ) { url, error in
            if let error {
                delegate?.singleSignOnErrored(error: error)
                return
            }
            guard let url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let stateItem = components.queryItems?.first(where: { $0.name == "state" }),
                  stateItem.value == state,
                  let codeItem = components.queryItems?.first(where: { $0.name == "code" }),
                  let code = codeItem.value
            else {
                delegate?.singleSignOnErrored(error: AuthError.unableToDecodeSSOResponse)
                return
            }
            delegate?.singleSignOnCompleted(code: code)
        }

        // prefersEphemeralWebBrowserSession should be false to allow access to the hCaptcha accessibility
        // cookie set in the default browser: https://www.hcaptcha.com/accessibility
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = self
        session.start()
    }

    /// Show the two factor authentication view.
    ///
    /// - Parameter data: The data required for the two-factor flow.
    ///
    private func showTwoFactorAuth(email: String, password: String?, authMethodsData: AuthMethodsData) {
        let state = TwoFactorAuthState(
            authMethodsData: authMethodsData,
            email: email,
            password: password
        )
        let processor = TwoFactorAuthProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: state
        )
        let view = TwoFactorAuthView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        stackNavigator.present(navigationController)
    }

    /// Shows the vault unlock view.
    ///
    /// - Parameters:
    ///   - account: The active account.
    ///   - animated: Whether to animate the transition.
    ///   - attemptAutmaticBiometricUnlock: Whether to the processor should attempt a biometric unlock on appear.
    ///   - didSwitchAccountAutomatically: A flag indicating if the active account was switched automatically.
    ///
    private func showVaultUnlock(
        account: Account,
        animated: Bool,
        attemptAutmaticBiometricUnlock: Bool,
        didSwitchAccountAutomatically: Bool
    ) {
        let processor = VaultUnlockProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: asAnyCoordinator(),
            services: services,
            state: VaultUnlockState(account: account)
        )
        processor.shouldAttemptAutomaticBiometricUnlock = attemptAutmaticBiometricUnlock
        let view = VaultUnlockView(store: Store(processor: processor))
        stackNavigator.replace(view, animated: animated)
        if didSwitchAccountAutomatically {
            processor.state.toast = Toast(text: Localizations.accountSwitchedAutomatically)
        }
    }

    /// Configures state and suggests a redirect for the switch accounts route.
    ///
    /// - Parameters:
    ///   - isUserInitiated: Did the user trigger the account switch?
    ///   - userId: The user Id of the selected account.
    /// - Returns: A suggested route for the active account with state pre-configured.
    ///
    private func switchAccountRedirect(isUserInitiated: Bool, userId: String) async -> AuthRoute {
        if let account = try? await services.stateService.getActiveAccount(),
           userId == account.profile.userId {
            return await prepareAndRedirect(
                .vaultUnlock(
                    account,
                    animated: false,
                    attemptAutomaticBiometricUnlock: true,
                    didSwitchAccountAutomatically: false
                )
            )
        }
        do {
            let activeAccount = try await services.authRepository.setActiveAccount(userId: userId)
            let redirect = AuthRoute.vaultUnlock(
                activeAccount,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: !isUserInitiated
            )
            return await prepareAndRedirect(redirect)
        } catch {
            services.errorReporter.log(error: error)
            return .landing
        }
    }

    /// Configures state and suggests a redirect for the `.vaultUnlock` route.
    ///
    /// - Parameters:
    ///     - activeAccount: The active account.
    ///     - animated: If the suggested route can be animated, use this value.
    ///     - shouldAttemptAutomaticBiometricUnlock: If the route uses automatic bioemtrics unlock,
    ///         this value enables or disables the feature.
    ///     - shouldAttemptAccountSwitch: Should the application automatically switch accounts for the user?
    /// - Returns: A suggested route for the active account with state pre-configured.
    ///
    private func vaultUnlockRedirect(
        _ activeAccount: Account,
        animated: Bool,
        attemptAutomaticBiometricUnlock: Bool,
        didSwitchAccountAutomatically: Bool
    ) async -> AuthRoute {
        let userId = activeAccount.profile.userId
        do {
            // Check for Never Lock.
            let isLocked = try? await services.authRepository.isLocked(userId: userId)
            let vaultTimeout = try? await services.vaultTimeoutService.sessionTimeoutValue(userId: userId)

            switch (vaultTimeout, isLocked) {
            case (.never, true):
                // If the user has enabled Never Lock, but the vault is locked,
                //  unlock the vault and return `.complete`.
                try await services.authRepository.unlockVaultWithNeverlockKey()
                return .complete
            case (_, false):
                // If the  vault is unlocked, return `.complete`.
                return .complete
            default:
                // Otherwise, return `.vaultUnlock`.
                return .vaultUnlock(
                    activeAccount,
                    animated: animated,
                    attemptAutomaticBiometricUnlock: attemptAutomaticBiometricUnlock,
                    didSwitchAccountAutomatically: didSwitchAccountAutomatically
                )
            }
        } catch {
            // In case of an error, go to `.vaultUnlock` for the active user.
            services.errorReporter.log(error: error)
            return .vaultUnlock(
                activeAccount,
                animated: animated,
                attemptAutomaticBiometricUnlock: attemptAutomaticBiometricUnlock,
                didSwitchAccountAutomatically: didSwitchAccountAutomatically
            )
        }
    }
}

public struct Splash: View, Equatable {
    // MARK: Properties

    /// The background color
    ///
    let backgroundColor: Color

    /// Should the nav bar be hidden?
    ///
    let hidesNavBar: Bool

    /// Should the view display the logo?
    ///
    let showsLogo: Bool

    public var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            if showsLogo {
                Asset.Images.logo.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 238)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(hidesNavBar)
        .navigationBarBackButtonHidden(hidesNavBar)
    }

    // MARK: Initializers

    public init(
        backgroundColor: Color = Asset.Colors.backgroundPrimary.swiftUIColor,
        hidesNavBar: Bool = true,
        showsLogo: Bool = true
    ) {
        self.backgroundColor = backgroundColor
        self.hidesNavBar = hidesNavBar
        self.showsLogo = showsLogo
    }
}

// MARK: ASWebAuthenticationPresentationContextProviding

extension AuthCoordinator: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        stackNavigator.rootViewController?.view.window ?? UIWindow()
    }
} // swiftlint:disable:this file_length
