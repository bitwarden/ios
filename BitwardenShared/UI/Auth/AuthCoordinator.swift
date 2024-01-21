import AuthenticationServices
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
        case .loginWithDevice:
            showLoginWithDevice()
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
        case let .switchAccount(userId: userId):
            selectAccount(for: userId)
        case let .twoFactor(email, password, authMethodsData):
            showTwoFactorAuth(email: email, password: password, authMethodsData: authMethodsData)
        case let .vaultUnlock(account, animated, attemptAutomaticBiometricUnlock):
            showVaultUnlock(
                account: account,
                animated: animated,
                attemptAutmaticBiometricUnlock: attemptAutomaticBiometricUnlock
            )
        }
    }

    func start() {
        rootNavigator?.show(child: stackNavigator)
    }

    // MARK: Private Methods

    /// Selects the account for a given userId and navigates to the correct point
    ///
    /// - Parameter userId: The user id of the selected account.
    private func selectAccount(for userId: String) {
        Task {
            do {
                let account = try await services.authRepository.setActiveAccount(userId: userId)
                let isLocked = try services.vaultTimeoutService.isLocked(userId: userId)
                if isLocked {
                    showVaultUnlock(account: account, animated: false, attemptAutmaticBiometricUnlock: true)
                } else {
                    delegate?.didCompleteAuth()
                }
            } catch {
                services.errorReporter.log(error: error)
                showLanding()
            }
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
    private func showLanding() {
        if stackNavigator.popToRoot(animated: UI.animated).isEmpty {
            let processor = LandingProcessor(
                coordinator: asAnyCoordinator(),
                services: services,
                state: LandingState()
            )
            let store = Store(processor: processor)
            let view = LandingView(store: store)
            stackNavigator.replace(view, animated: false)
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
    private func showLoginWithDevice() {
        let processor = LoginWithDeviceProcessor(
            coordinator: asAnyCoordinator(),
            state: LoginWithDeviceState()
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
    private func showTwoFactorAuth(email: String, password: String?, authMethodsData: [String: [String: String]]) {
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
    ///
    private func showVaultUnlock(
        account: Account,
        animated: Bool = true,
        attemptAutmaticBiometricUnlock: Bool = false
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
    }
}

// MARK: ASWebAuthenticationPresentationContextProviding

extension AuthCoordinator: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        stackNavigator.rootViewController?.view.window ?? UIWindow()
    }
} // swiftlint:disable:this file_length
