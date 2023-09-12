import UIKit

// MARK: - AppCoordinator

/// A coordinator that manages the app's top-level navigation.
///
public class AppCoordinator: Coordinator {
    // MARK: Types

    /// The types of modules used by this coordinator.
    public typealias Module = AuthModule

    // MARK: Private Properties

    /// The coordinator currently being displayed.
    private var childCoordinator: AnyObject?

    // MARK: Properties

    /// The module to use for creating child coordinators.
    public let module: Module

    /// The navigator to use for presenting screens.
    public let navigator: RootNavigator

    // MARK: Initialization

    /// Creates a new `AppCoordinator`.
    ///
    /// - Parameters:
    ///   - module: The module to use for creating child coordinators.
    ///   - navigator: The navigator to use for presenting screens.
    ///
    public init(module: Module, navigator: RootNavigator) {
        self.module = module
        self.navigator = navigator
    }

    // MARK: Methods

    public func navigate(to route: AppRoute, context: AnyObject?) {
        switch route {
        case let .auth(authRoute):
            showAuth(route: authRoute)
        }
    }

    public func start() {
        showAuth(route: .landing)
    }

    // MARK: Private Methods

    /// Shows the auth route.
    ///
    /// - Parameter route: The auth route to show.
    ///
    private func showAuth(route: AuthRoute) {
        if let coordinator = childCoordinator as? AnyCoordinator<AuthRoute> {
            coordinator.navigate(to: route)
        } else {
            let navigationController = UINavigationController()
            let coordinator = module.makeAuthCoordinator(
                rootNavigator: navigator,
                stackNavigator: navigationController
            )
            coordinator.start()
            coordinator.navigate(to: route)
            childCoordinator = coordinator
        }
    }
}
