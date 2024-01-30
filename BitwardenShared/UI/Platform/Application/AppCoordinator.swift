import BitwardenSdk
import SwiftUI
import UIKit

// MARK: - AppCoordinator

/// A coordinator that manages the app's top-level navigation.
///
class AppCoordinator: Coordinator, HasRootNavigator {
    // MARK: Types

    /// The types of modules used by this coordinator.
    typealias Module = AuthModule
        & ExtensionSetupModule
        & FileSelectionModule
        & LoginRequestModule
        & SendItemModule
        & TabModule
        & VaultModule

    // MARK: Private Properties

    /// The context that the app is running within.
    private let appContext: AppContext

    /// A delegate used to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    /// The coordinator currently being displayed.
    private var childCoordinator: AnyObject?

    // MARK: Properties

    /// The module to use for creating child coordinators.
    let module: Module

    /// The navigator to use for presenting screens.
    private(set) weak var rootNavigator: RootNavigator?

    // MARK: Initialization

    /// Creates a new `AppCoordinator`.
    ///
    /// - Parameters:
    ///   - appContext: The context that the app is running within.
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - module: The module to use for creating child coordinators.
    ///   - rootNavigator: The navigator to use for presenting screens.
    ///
    init(
        appContext: AppContext,
        appExtensionDelegate: AppExtensionDelegate?,
        module: Module,
        rootNavigator: RootNavigator
    ) {
        self.appContext = appContext
        self.appExtensionDelegate = appExtensionDelegate
        self.module = module
        self.rootNavigator = rootNavigator
    }

    // MARK: Methods

    func handleEvent(_ event: AppEvent, context: AnyObject?) async {
        switch event {
        case .didStart:
            await handleAuthEvent(.didStart)
        case let .didTimeout(userId):
            await handleAuthEvent(.didTimeout(userId: userId))
        }
    }

    func navigate(to route: AppRoute, context _: AnyObject?) {
        switch route {
        case let .auth(authRoute):
            showAuth(authRoute)
        case let .extensionSetup(extensionSetupRoute):
            showExtensionSetup(route: extensionSetupRoute)
        case let .loginRequest(loginRequest):
            showLoginRequest(loginRequest)
        case let .sendItem(sendItemRoute):
            showSendItem(route: sendItemRoute)
        case let .tab(tabRoute):
            showTab(route: tabRoute)
        case let .vault(vaultRoute):
            showVault(route: vaultRoute)
        }
    }

    func start() {
        // Nothing to do here - the initial route is specified by `AppProcessor` and this
        // coordinator doesn't need to navigate within the `Navigator` since it's the root.
    }

    // MARK: Private Methods

    /// Handle an auth event.
    ///
    /// - Parameter event: The auth event to handle.
    ///
    private func handleAuthEvent(_ authEvent: AuthEvent) async {
        let router = module.makeAuthRouter()
        let route = await router.handleAndRoute(authEvent)
        showAuth(route)
    }

    /// Shows the auth route.
    ///
    /// - Parameter route: The auth route to show.
    ///
    private func showAuth(_ authRoute: AuthRoute) {
        if let coordinator = childCoordinator as? AnyCoordinator<AuthRoute, AuthEvent> {
            coordinator.navigate(to: authRoute)
        } else {
            guard let rootNavigator else { return }
            let navigationController = UINavigationController()
            let coordinator = module.makeAuthCoordinator(
                delegate: self,
                rootNavigator: rootNavigator,
                stackNavigator: navigationController
            )

            coordinator.start()
            childCoordinator = coordinator
            coordinator.navigate(to: authRoute)
        }
    }

    /// Shows the extension setup route.
    ///
    /// - Parameter route: The extension setup route to show.
    ///
    private func showExtensionSetup(route: ExtensionSetupRoute) {
        if let coordinator = childCoordinator as? AnyCoordinator<ExtensionSetupRoute, Void> {
            coordinator.navigate(to: route)
        } else {
            let stackNavigator = UINavigationController()
            let coordinator = module.makeExtensionSetupCoordinator(
                stackNavigator: stackNavigator
            )
            coordinator.start()
            coordinator.navigate(to: route)
            childCoordinator = coordinator
            rootNavigator?.show(child: stackNavigator)
        }
    }

    /// Shows the send item route (not in a tab). This is used within the app extensions.
    ///
    /// - Parameter route: The `SendItemRoute` to show.
    ///
    private func showSendItem(route: SendItemRoute) {
        if let coordinator = childCoordinator as? AnyCoordinator<SendItemRoute, Void> {
            coordinator.navigate(to: route)
        } else {
            let stackNavigator = UINavigationController()
            let coordinator = module.makeSendItemCoordinator(
                delegate: self,
                stackNavigator: stackNavigator
            )
            coordinator.start()
            coordinator.navigate(to: route)
            childCoordinator = coordinator
            rootNavigator?.show(child: stackNavigator)
        }
    }

    /// Shows the tab route.
    ///
    /// - Parameter route: The tab route to show.
    ///
    private func showTab(route: TabRoute) {
        if let coordinator = childCoordinator as? AnyCoordinator<TabRoute, Void> {
            coordinator.navigate(to: route)
        } else {
            guard let rootNavigator else { return }
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

    /// Show the login request.
    ///
    /// - Parameter loginRequest: The login request to show.
    ///
    private func showLoginRequest(_ loginRequest: LoginRequest) {
        DispatchQueue.main.async {
            // Make sure that the user is authenticated and not currently viewing the login request view.
            guard self.childCoordinator is AnyCoordinator<TabRoute, Void> else { return }
            let currentView = self.rootNavigator?.rootViewController?.topmostViewController()
            guard !(currentView is UIHostingController<LoginRequestView>) else { return }

            // Create the login request view.
            let navigationController = UINavigationController()
            let coordinator = self.module.makeLoginRequestCoordinator(stackNavigator: navigationController)
            coordinator.start()
            coordinator.navigate(to: .loginRequest(loginRequest), context: self)

            // Present the login request view.
            self.rootNavigator?.rootViewController?.topmostViewController().present(
                navigationController,
                animated: true
            )
        }
    }

    /// Shows the vault route (not in a tab). This is used within the app extensions.
    ///
    /// - Parameter route: The vault route to show.
    ///
    private func showVault(route: VaultRoute) {
        if let coordinator = childCoordinator as? AnyCoordinator<VaultRoute, AuthAction> {
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
            rootNavigator?.show(child: stackNavigator)
        }
    }
}

// MARK: - AuthCoordinatorDelegate

extension AppCoordinator: AuthCoordinatorDelegate {
    func didCompleteAuth() {
        switch appContext {
        case .appExtension:
            let route = appExtensionDelegate?.authCompletionRoute ?? .vault(.autofillList)
            navigate(to: route)
        case .mainApp:
            showTab(route: .vault(.list))
        }
    }
}

// MARK: - LoginRequestDelegate

extension AppCoordinator: LoginRequestDelegate {
    /// Show a toast over the current window with the result of answering the login request.
    ///
    /// - Parameter approved: Whether the login request was approved or denied.
    ///
    func loginRequestAnswered(approved: Bool) {
        showToast(approved ? Localizations.loginApproved : Localizations.logInDenied)
    }
}

// MARK: - SendItemDelegate

extension AppCoordinator: SendItemDelegate {
    func sendItemCancelled() {
        appExtensionDelegate?.didCancel()
    }

    func sendItemCompleted(with sendView: BitwardenSdk.SendView) {
        appExtensionDelegate?.didCancel()
    }

    func sendItemDeleted() {
        appExtensionDelegate?.didCancel()
    }
}

// MARK: - SettingsCoordinatorDelegate

extension AppCoordinator: SettingsCoordinatorDelegate {
    func didDeleteAccount() {
        Task {
            await handleAuthEvent(.didDeleteAccount)
        }
    }

    func lockVault(userId: String?) {
        Task {
            await handleAuthEvent(
                .action(
                    .lockVault(userId: userId)
                )
            )
        }
    }

    func logout(userId: String?, userInitiated: Bool) {
        Task {
            await handleAuthEvent(
                .action(
                    .logout(userId: userId, userInitiated: userInitiated)
                )
            )
        }
    }

    func switchAccount(isAutomatic: Bool, userId: String) {
        Task {
            await handleAuthEvent(
                .action(
                    .switchAccount(
                        isAutomatic: isAutomatic,
                        userId: userId
                    )
                )
            )
        }
    }
}

// MARK: - VaultCoordinatorDelegate

extension AppCoordinator: VaultCoordinatorDelegate {
    func switchAccount(userId: String, isAutomatic: Bool) {
        Task {
            await handleAuthEvent(
                .action(
                    .switchAccount(
                        isAutomatic: isAutomatic,
                        userId: userId
                    )
                )
            )
        }
    }

    func didTapAddAccount() {
        showAuth(.landing)
    }

    func didTapAccount(userId: String) {
        Task {
            await handleAuthEvent(
                .action(
                    .switchAccount(
                        isAutomatic: false,
                        userId: userId
                    )
                )
            )
        }
    }

    func presentLoginRequest(_ loginRequest: LoginRequest) {
        showLoginRequest(loginRequest)
    }
}
