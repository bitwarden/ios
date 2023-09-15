import SwiftUI
import UIKit

// MARK: - AuthCoordinator

/// A coordinator that manages navigation in the authentication flow.
///
internal final class AuthCoordinator: Coordinator {
    // MARK: Properties

    /// The root navigator used to display this coordinator's interface.
    weak var rootNavigator: (any RootNavigator)?

    /// The stack navigator that is managed by this coordinator.
    var stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `AuthCoordinator`.
    ///
    /// - Parameters:
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        rootNavigator: RootNavigator,
        stackNavigator: StackNavigator
    ) {
        self.rootNavigator = rootNavigator
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: AuthRoute, context: AnyObject?) {
        switch route {
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
