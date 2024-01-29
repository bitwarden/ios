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
    let rootNavigator: RootNavigator

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

    func navigate(to route: AppRoute, context _: AnyObject?) {
        switch route {
        case let .auth(authRoute):
            showAuth(route: authRoute)
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

    /// Shows the extension setup route.
    ///
    /// - Parameter route: The extension setup route to show.
    ///
    private func showExtensionSetup(route: ExtensionSetupRoute) {
        if let coordinator = childCoordinator as? AnyCoordinator<ExtensionSetupRoute> {
            coordinator.navigate(to: route)
        } else {
            let stackNavigator = UINavigationController()
            let coordinator = module.makeExtensionSetupCoordinator(
                stackNavigator: stackNavigator
            )
            coordinator.start()
            coordinator.navigate(to: route)
            childCoordinator = coordinator
            rootNavigator.show(child: stackNavigator)
        }
    }

    /// Shows the send item route (not in a tab). This is used within the app extensions.
    ///
    /// - Parameter route: The `SendItemRoute` to show.
    ///
    private func showSendItem(route: SendItemRoute) {
        if let coordinator = childCoordinator as? AnyCoordinator<SendItemRoute> {
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
            rootNavigator.show(child: stackNavigator)
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

    /// Show the login request.
    ///
    /// - Parameter loginRequest: The login request to show.
    ///
    private func showLoginRequest(_ loginRequest: LoginRequest) {
        DispatchQueue.main.async {
            // Make sure that the user is authenticated and not currently viewing the login request view.
            guard self.childCoordinator is AnyCoordinator<TabRoute> else { return }
            let currentView = self.rootNavigator.rootViewController?.topmostViewController()
            guard !(currentView is UIHostingController<LoginRequestView>) else { return }

            // Create the login request view.
            let navigationController = UINavigationController()
            let coordinator = self.module.makeLoginRequestCoordinator(stackNavigator: navigationController)
            coordinator.start()
            coordinator.navigate(to: .loginRequest(loginRequest), context: self)

            // Present the login request view.
            self.rootNavigator.rootViewController?.topmostViewController().present(
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
    func didDeleteAccount(otherAccounts: [Account]?) {
        if let account = otherAccounts?.first {
            showAuth(
                route: .vaultUnlock(
                    account,
                    didSwitchAccountAutomatically: true
                )
            )
        } else {
            showAuth(route: .landing)
        }
        showAuth(route: .alert(.accountDeletedAlert()))
    }

    func didLockVault(account: Account) {
        showAuth(route: .vaultUnlock(account, didSwitchAccountAutomatically: false))
    }

    func didLogout(userInitiated: Bool, otherAccounts: [Account]?) {
        if userInitiated,
           let account = otherAccounts?.first {
            showAuth(
                route: .vaultUnlock(
                    account,
                    attemptAutomaticBiometricUnlock: true,
                    didSwitchAccountAutomatically: true
                )
            )
        } else {
            showAuth(route: .landing)
        }
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

    func presentLoginRequest(_ loginRequest: LoginRequest) {
        showLoginRequest(loginRequest)
    }
}
