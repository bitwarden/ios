import BitwardenResources
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
        & DebugMenuModule
        & ExtensionSetupModule
        & FileSelectionModule
        & LoginRequestModule
        & NavigatorBuilderModule
        & SendItemModule
        & TabModule
        & VaultModule

    // MARK: Private Properties

    /// The context that the app is running within.
    private let appContext: AppContext

    /// A delegate used to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    /// A route to navigate to after auth completes.
    private(set) var authCompletionRoute: AppRoute?

    /// The coordinator currently being displayed.
    private var childCoordinator: AnyObject?

    /// Whether the debug menu is currently being shown.
    private(set) var isShowingDebugMenu = false

    // MARK: Properties

    /// The module to use for creating child coordinators.
    let module: Module

    /// The navigator to use for presenting screens.
    private(set) weak var rootNavigator: RootNavigator?

    /// The service container used by the coordinator
    private let services: Services

    // MARK: Initialization

    /// Creates a new `AppCoordinator`.
    ///
    /// - Parameters:
    ///   - appContext: The context that the app is running within.
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - module: The module to use for creating child coordinators.
    ///   - rootNavigator: The navigator to use for presenting screens.
    ///   - services: The service container used by the coordinator.
    ///
    init(
        appContext: AppContext,
        appExtensionDelegate: AppExtensionDelegate?,
        module: Module,
        rootNavigator: RootNavigator,
        services: Services
    ) {
        self.appContext = appContext
        self.appExtensionDelegate = appExtensionDelegate
        self.module = module
        self.rootNavigator = rootNavigator
        self.services = services
    }

    // MARK: Methods

    func handleEvent(_ event: AppEvent, context: AnyObject?) async {
        switch event {
        case let .accountBecameActive(
            account,
            attemptAutomaticBiometricUnlock,
            didSwitchAccountAutomatically
        ):
            await handleAuthEvent(
                .accountBecameActive(
                    account,
                    animated: true,
                    attemptAutomaticBiometricUnlock: attemptAutomaticBiometricUnlock,
                    didSwitchAccountAutomatically: didSwitchAccountAutomatically
                )
            )
        case let .didLogout(userId, userInitiated):
            await handleAuthEvent(.didLogout(userId: userId, userInitiated: userInitiated))
        case .didStart:
            await handleAuthEvent(.didStart)
        case let .didTimeout(userId):
            await handleAuthEvent(.didTimeout(userId: userId))
        case let .setAuthCompletionRoute(route):
            authCompletionRoute = route
        case let .switchAccounts(userId, isAutomatic):
            await handleAuthEvent(
                .action(
                    .switchAccount(
                        isAutomatic: isAutomatic,
                        userId: userId,
                        authCompletionRoute: nil
                    )
                )
            )
        }
    }

    func navigate(to route: AppRoute, context _: AnyObject?) {
        switch route {
        case let .auth(authRoute):
            showAuth(authRoute)
        case .debugMenu:
            showDebugMenu()
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

        // HACK: This is needed for the case when we have all of the next:
        // - Autofill with Fido2 credential
        // - Never timeout
        // - Needs user interaction because of user verification
        // When this happens, then sometimes the biometrics prompt may not be shown to the user
        // because some race condition from the OS showing the view vs displaying the bio prompt.
        // To fix this we show a transparent navigation controller which makes the
        // biometric prompt work again.
        if route == .completeWithNeverUnlockKey,
           let autofillAppExtensionDelegate = appExtensionDelegate as? AutofillAppExtensionDelegate,
           case .autofillFido2Credential = autofillAppExtensionDelegate.extensionMode {
            showTransparentController()
            didCompleteAuth(rehydratableTarget: nil)
            return
        }

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
            let navigationController = module.makeNavigationController()
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
            let stackNavigator = module.makeNavigationController()
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
            let stackNavigator = module.makeNavigationController()
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
            let tabNavigator = BitwardenTabBarController()
            let coordinator = module.makeTabCoordinator(
                errorReporter: services.errorReporter,
                rootNavigator: rootNavigator,
                settingsDelegate: self,
                tabNavigator: tabNavigator,
                vaultDelegate: self,
                vaultRepository: services.vaultRepository
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
            let navigationController = self.module.makeNavigationController()
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

    /// Adds a transparent navigation controller to the root navigator.
    /// This is needed for the Autofill Fido2 flow when unlocking with the never unlock key
    /// and performing user verification. If we don't do this, the biometrics prompt may not be presented
    /// to the user and will always be treated as failed by the OS.
    private func showTransparentController() {
        guard let rootNavigator else { return }
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        rootNavigator.show(child: navigationController)
    }

    /// Shows the vault route (not in a tab). This is used within the app extensions.
    ///
    /// - Parameter route: The vault route to show.
    ///
    private func showVault(route: VaultRoute) {
        if let coordinator = childCoordinator as? AnyCoordinator<VaultRoute, AuthAction> {
            coordinator.navigate(to: route)
        } else {
            let stackNavigator = module.makeNavigationController()
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

    /// Configures and presents the debug menu.
    ///
    /// Initializes feedback generator for haptic feedback. Sets up a `UINavigationController`
    /// and creates / starts a `DebugMenuCoordinator` to manage the debug menu flow.
    /// Presents the navigation controller and triggers haptic feedback upon completion.
    ///
    private func showDebugMenu() {
        guard !isShowingDebugMenu else { return }

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        let stackNavigator = UINavigationController()
        stackNavigator.navigationBar.prefersLargeTitles = true
        stackNavigator.modalPresentationStyle = .fullScreen
        let debugMenuCoordinator = module.makeDebugMenuCoordinator(delegate: self, stackNavigator: stackNavigator)
        debugMenuCoordinator.start()

        rootNavigator?.rootViewController?.topmostViewController().present(
            stackNavigator,
            animated: true,
            completion: { feedbackGenerator.impactOccurred() }
        )
        isShowingDebugMenu = true
    }
}

// MARK: - AuthCoordinatorDelegate

extension AppCoordinator: AuthCoordinatorDelegate {
    func didCompleteAuth(rehydratableTarget: RehydratableTarget?) {
        appExtensionDelegate?.didCompleteAuth()

        switch appContext {
        case .appExtension:
            guard let appExtensionDelegate else {
                navigate(to: .vault(.autofillList))
                return
            }

            guard let route = appExtensionDelegate.authCompletionRoute else { return }
            navigate(to: route)
        case .mainApp:
            showTab(route: .vault(.list))

            if let rehydratableTarget {
                navigate(to: rehydratableTarget.appRoute)
                Task {
                    do {
                        try await services.rehydrationHelper.clearAppRehydrationState()
                    } catch {
                        services.errorReporter.log(error: error)
                    }
                }
                return
            }

            if let authCompletionRoute {
                navigate(to: authCompletionRoute)
                self.authCompletionRoute = nil
            }
        }
    }
}

// MARK: - DebugMenuCoordinatorDelegate

extension AppCoordinator: DebugMenuCoordinatorDelegate {
    func didDismissDebugMenu() {
        isShowingDebugMenu = false
    }
}

// MARK: - HasErrorAlertServices

extension AppCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
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
    func handle(_ authAction: AuthAction) async {
        await handleAuthEvent(.action(authAction))
    }

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
    func didCompleteLoginsImport() {
        navigate(to: .tab(.vault(.list)))
        showToast(
            Localizations.loginsImported,
            subtitle: Localizations.rememberToDeleteYourImportedPasswordFileFromYourComputer,
            additionalBottomPadding: FloatingActionButton.bottomOffsetPadding
        )
    }

    func didDeleteAccount() {
        Task {
            await handleAuthEvent(.didDeleteAccount)

            showAlert(.accountDeletedAlert())
        }
    }

    func lockVault(userId: String?, isManuallyLocking: Bool) {
        Task {
            await handleAuthEvent(
                .action(
                    .lockVault(userId: userId, isManuallyLocking: isManuallyLocking)
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
    func switchAccount(userId: String, isAutomatic: Bool, authCompletionRoute: AppRoute?) {
        Task {
            self.authCompletionRoute = authCompletionRoute
            await handleAuthEvent(
                .action(
                    .switchAccount(
                        isAutomatic: isAutomatic,
                        userId: userId,
                        authCompletionRoute: authCompletionRoute
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

    func switchToSettingsTab(route: SettingsRoute) {
        navigate(to: .tab(.settings(route)))
    }
} // swiftlint:disable:this file_length
