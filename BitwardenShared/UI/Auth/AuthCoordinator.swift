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
internal final class AuthCoordinator: Coordinator {
    typealias Services = HasAuthAPIService

    // MARK: Properties

    /// The delegate for this coordinator. Used to signal when auth has been completed.
    weak var delegate: (any AuthCoordinatorDelegate)?

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
        case .complete:
            delegate?.didCompleteAuth()
        case .createAccount:
            showCreateAccount()
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
        case .regionSelection:
            showRegionSelection()
        }
    }

    func start() {
        rootNavigator?.show(child: stackNavigator)
    }

    // MARK: Private Methods

    /// Shows the create account screen.
    private func showCreateAccount() {
        let view = CreateAccountView(
            store: Store(
                processor: CreateAccountProcessor(
                    coordinator: asAnyCoordinator(),
                    state: CreateAccountState()
                )
            )
        )
        stackNavigator.push(view)
    }

    /// Shows the enterprise single sign-on screen.
    private func showEnterpriseSingleSignOn() {
        let view = Text("Enterprise Single Sign-On")
        stackNavigator.push(view)
    }

    /// Shows the landing screen.
    private func showLanding() {
        if stackNavigator.popToRoot(animated: UI.animated).isEmpty {
            let processor = LandingProcessor(
                coordinator: asAnyCoordinator(),
                state: LandingState()
            )
            let store = Store(processor: processor)
            let view = LandingView(store: store)
            stackNavigator.push(view)
        }
    }

    /// Shows the login screen.
    ///
    /// - Parameter state: The `LoginState` to initialize the login screen with.
    ///
    private func showLogin(state: LoginState) {
        let processor = LoginProcessor(
            coordinator: asAnyCoordinator(),
            state: state
        )
        let store = Store(processor: processor)
        let view = LoginView(store: store)
        stackNavigator.push(view)
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

    /// Shows the region selection screen.
    private func showRegionSelection() {
        let view = Text("Region")
        stackNavigator.push(view)
    }
}
