import UIKit

// MARK: - AppCoordinator

/// A coordinator that manages the app's top-level navigation.
///
class AppCoordinator: Coordinator, HasRootNavigator {
    // MARK: Types

    /// The types of modules used by this coordinator.
    typealias Module = AuthModule
        & TabModule
        & VaultModule

    // MARK: Private Properties

    /// The context that the app is running within.
    private let appContext: AppContext

    /// The coordinator currently being displayed.
    private var childCoordinator: AnyObject?

    // MARK: Properties

    /// The module to use for creating child coordinators.
    let module: Module

    /// The navigator to use for presenting screens.
    let rootNavigator: RootNavigator

    // MARK: Initialization

    /// Creates a new `AppCoordinator`.
    ///
    /// - Parameters:
    ///   - appContext: The context that the app is running within.
    ///   - module: The module to use for creating child coordinators.
    ///   - rootNavigator: The navigator to use for presenting screens.
    ///
    init(
        appContext: AppContext,
        module: Module,
        rootNavigator: RootNavigator
    ) {
        self.appContext = appContext
        self.module = module
        self.rootNavigator = rootNavigator
    }

    // MARK: Methods

    func navigate(to route: AppRoute, context: AnyObject?) {
        switch route {
        case let .auth(authRoute):
            showAuth(route: authRoute)
        case let .tab(tabRoute):
            showTab(route: tabRoute)
        }
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
                rootNavigator: rootNavigator,
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
                rootNavigator: rootNavigator,
                settingsDelegate: self,
                tabNavigator: tabNavigator,
                vaultDelegate: self
            )
            coordinator.start()
            coordinator.navigate(to: route)
            childCoordinator = coordinator
        }
    }

    /// Shows the vault route (not in a tab). This is used within the app extensions.
    ///
    /// - Parameter route: The vault route to show.
    ///
    private func showVault(route: VaultRoute) {
        if let coordinator = childCoordinator as? AnyCoordinator<VaultRoute> {
            coordinator.navigate(to: route)
        } else {
            let stackNavigator = UINavigationController()
            let coordinator = module.makeVaultCoordinator(
                delegate: self,
                stackNavigator: stackNavigator
            )
            coordinator.start()
            coordinator.navigate(to: route)
            childCoordinator = coordinator
            rootNavigator.show(child: stackNavigator)
        }
    }
}

// MARK: - AuthCoordinatorDelegate

extension AppCoordinator: AuthCoordinatorDelegate {
    func didCompleteAuth() {
        switch appContext {
        case .mainApp:
            showTab(route: .vault(.list))
        case .appExtension:
            showVault(route: .autofillList)
        }
    }
}

// MARK: - SettingsCoordinatorDelegate

extension AppCoordinator: SettingsCoordinatorDelegate {
    func didDeleteAccount(otherAccounts: [Account]?) {
        if let account = otherAccounts?.first {
            showAuth(route: .vaultUnlock(account))
        } else {
            showAuth(route: .landing)
        }
        showAuth(route: .alert(.accountDeletedAlert()))
    }

    func didLockVault(account: Account) {
        showAuth(route: .vaultUnlock(account))
    }

    func didLogout() {
        showAuth(route: .landing)
    }
}

// MARK: - VaultCoordinatorDelegate

extension AppCoordinator: VaultCoordinatorDelegate {
    func didTapAddAccount() {
        showAuth(route: .landing)
    }

    func didTapAccount(userId: String) {
        showAuth(route: .switchAccount(userId: userId))
    }
}
