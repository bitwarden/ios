import SwiftUI
import UIKit

// MARK: - AuthCoordinator

/// A coordinator that manages navigation in the authentication flow.
///
internal final class AuthCoordinator: Coordinator {
    // MARK: Properties

    /// The root navigator used to display this coordinator's interface.
    private weak var rootNavigator: (any RootNavigator)?

    /// The stack navigator that is managed by this coordinator.
    private var stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `AuthCoordinator`.
    ///
    /// - Parameters:
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        rootNavigator: RootNavigator?,
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
        case .landing:
            showLanding()
        case .login:
            showLogin()
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
        let view = Text("Create Account")
        stackNavigator.push(view, animated: UI.animated)
    }

    /// Shows the landing screen.
    private func showLanding() {
        let processor = LandingProcessor(
            coordinator: asAnyCoordinator(),
            state: LandingState()
        )
        let store = Store(processor: processor)
        let view = LandingView(store: store)
        stackNavigator.push(view, animated: UI.animated)
    }

    /// Shows the login screen.
    private func showLogin() {
        let view = Text("Login")
        stackNavigator.push(view, animated: UI.animated)
    }

    /// Shows the region selection screen.
    private func showRegionSelection() {
        let view = Text("Region")
        stackNavigator.push(view, animated: UI.animated)
    }
}
