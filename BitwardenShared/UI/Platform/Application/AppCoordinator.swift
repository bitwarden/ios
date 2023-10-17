import UIKit

// MARK: - AppCoordinator

/// A coordinator that manages the app's top-level navigation.
///
class AppCoordinator: Coordinator {
    // MARK: Types

    /// The types of modules used by this coordinator.
    typealias Module = AuthModule
        & TabModule

    // MARK: Private Properties

    /// The coordinator currently being displayed.
    private var childCoordinator: AnyObject?

    // MARK: Properties

    /// The module to use for creating child coordinators.
    let module: Module

    /// The navigator to use for presenting screens.
    let navigator: RootNavigator

    // MARK: Initialization

    /// Creates a new `AppCoordinator`.
    ///
    /// - Parameters:
    ///   - module: The module to use for creating child coordinators.
    ///   - navigator: The navigator to use for presenting screens.
    ///
    init(module: Module, navigator: RootNavigator) {
        self.module = module
        self.navigator = navigator
    }

    // MARK: Methods

    func hideLoadingOverlay() {
        navigator.hideLoadingOverlay()
    }

    func navigate(to route: AppRoute, context: AnyObject?) {
        switch route {
        case let .auth(authRoute):
            showAuth(route: authRoute)
        case let .tab(tabRoute):
            showTab(route: tabRoute)
        }
    }

    func showLoadingOverlay(_ state: LoadingOverlayState) {
        navigator.showLoadingOverlay(state)
    }

    func start() {
        // Nothing to do here - the initial route is specified by `AppProcessor` and this
        // coordinator doesn't need to navigate within the `Navigator` since it's the root.
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
                delegate: self,
                rootNavigator: navigator,
                stackNavigator: navigationController
            )
            coordinator.start()
            coordinator.navigate(to: route)
            childCoordinator = coordinator
        }
    }

    /// Shows the tab route.
    ///
    /// - Parameter route: The tab route to show.
    ///
    private func showTab(route: TabRoute) {
        if let coordinator = childCoordinator as? AnyCoordinator<TabRoute> {
            coordinator.navigate(to: route)
        } else {
            let tabNavigator = UITabBarController()
            let coordinator = module.makeTabCoordinator(
                rootNavigator: navigator,
                tabNavigator: tabNavigator
            )
            coordinator.start()
            coordinator.navigate(to: route)
            childCoordinator = coordinator
        }
    }
}

// MARK: - AuthCoordinatorDelegate

extension AppCoordinator: AuthCoordinatorDelegate {
    func didCompleteAuth() {
        showTab(route: .vault(.list))
    }
}
