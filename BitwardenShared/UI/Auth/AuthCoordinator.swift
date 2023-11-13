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
internal final class AuthCoordinator: NSObject, Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasAccountAPIService
        & HasAppIdService
        & HasAppSettingsStore
        & HasAuthAPIService
        & HasAuthRepository
        & HasCaptchaService
        & HasClientAuth
        & HasDeviceAPIService
        & HasErrorReporter
        & HasStateService
        & HasSystemDevice

    // MARK: Properties

    /// The delegate for this coordinator. Used to signal when auth has been completed.
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
    ///   - delegate: The delegate for this coordinator. Used to signal when auth has been completed.
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        delegate: AuthCoordinatorDelegate,
        rootNavigator: RootNavigator,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.delegate = delegate
        self.rootNavigator = rootNavigator
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: AuthRoute, context: AnyObject?) {
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
        case .enterpriseSingleSignOn:
            showEnterpriseSingleSignOn()
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
        case .masterPasswordHint:
            showMasterPasswordHint()
        case .selfHosted:
            showSelfHostedView()
        case let .vaultUnlock(account):
            showVaultUnlock(account: account)
        }
    }

    func start() {
        rootNavigator?.show(child: stackNavigator)
    }

    // MARK: Private Methods

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
    private func showEnterpriseSingleSignOn() {
        let view = Text("Enterprise Single Sign-On")
        stackNavigator.push(view)
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
        let view = Text("Login With Device")
        stackNavigator.push(view)
    }

    /// Shows the master password hint screen.
    private func showMasterPasswordHint() {
        let view = Text("Master Password Hint")
        stackNavigator.push(view)
    }

    /// Shows the self-hosted settings view.
    private func showSelfHostedView() {
        let processor = SelfHostedProcessor(
            coordinator: asAnyCoordinator(),
            state: SelfHostedState()
        )
        let view = SelfHostedView(store: Store(processor: processor))
        let navController = UINavigationController(rootViewController: UIHostingController(rootView: view))
        stackNavigator.present(navController)
    }

    /// Shows the vault unlock view.
    ///
    /// - Parameter account: The active account.
    ///
    private func showVaultUnlock(account: Account) {
        let processor = VaultUnlockProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: VaultUnlockState(account: account)
        )
        let view = VaultUnlockView(store: Store(processor: processor))
        stackNavigator.push(view)
    }
}

// MARK: ASWebAuthenticationPresentationContextProviding

extension AuthCoordinator: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        stackNavigator.rootViewController?.view.window ?? UIWindow()
    }
}
