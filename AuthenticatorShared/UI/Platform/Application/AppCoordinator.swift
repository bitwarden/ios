import BitwardenKit
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
        & ItemListModule
        & NavigatorBuilderModule
        & TabModule
        & TutorialModule

    // MARK: Private Properties

    /// The context that the app is running within.
    private let appContext: AppContext

    /// The coordinator currently being displayed.
    private var childCoordinator: AnyObject?

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
        module: Module,
        rootNavigator: RootNavigator,
        services: Services,
    ) {
        self.appContext = appContext
        self.module = module
        self.rootNavigator = rootNavigator
        self.services = services
    }

    // MARK: Methods

    func handleEvent(_ event: AppEvent, context: AnyObject?) async {
        switch event {
        case .didStart:
            let hasTimeout = await services.stateService.getVaultTimeout() != .never
            let isEnabled = await (try? services.biometricsRepository.getBiometricUnlockStatus().isEnabled) ?? false

            if isEnabled, hasTimeout {
                showAuth(.vaultUnlock)
            } else {
                showTab(route: .itemList(.list))
                if !services.stateService.hasSeenWelcomeTutorial {
                    showTutorial()
                }
            }
        case .vaultTimeout:
            showAuth(.vaultUnlock)
        }
    }

    func navigate(to route: AppRoute, context _: AnyObject?) {
        switch route {
        case .debugMenu:
            #if DEBUG_MENU
            showDebugMenu()
            #endif
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
    private func showAuth(_ authRoute: AuthRoute) {
        if let coordinator = childCoordinator as? AnyCoordinator<AuthRoute, AuthEvent> {
            coordinator.navigate(to: authRoute)
        } else {
            guard let rootNavigator else { return }
            let navigationController = module.makeNavigationController()
            let coordinator = module.makeAuthCoordinator(
                delegate: self,
                rootNavigator: rootNavigator,
                stackNavigator: navigationController,
            )

            coordinator.start()
            navigationController.modalPresentationStyle = .overFullScreen
            navigationController.isNavigationBarHidden = true
            rootNavigator.rootViewController?.present(navigationController, animated: false)
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
                itemListDelegate: self,
                rootNavigator: rootNavigator,
                tabNavigator: tabNavigator,
            )
            coordinator.start()
            coordinator.navigate(to: route)
            childCoordinator = coordinator
        }
        if let rootNavigator, rootNavigator.isPresenting {
            rootNavigator.rootViewController?.dismiss(animated: true)
        }
    }

    /// Shows the welcome tutorial.
    ///
    private func showTutorial() {
        let navigationController = module.makeNavigationController()
        let coordinator = module.makeTutorialCoordinator(
            stackNavigator: navigationController,
        )
        coordinator.start()

        navigationController.modalPresentationStyle = .overFullScreen
        rootNavigator?.rootViewController?.present(navigationController, animated: false)
    }

    #if DEBUG_MENU
    /// Configures and presents the debug menu.
    ///
    /// Initializes feedback generator for haptic feedback. Sets up a `UINavigationController`
    /// and creates / starts a `DebugMenuCoordinator` to manage the debug menu flow.
    /// Presents the navigation controller and triggers haptic feedback upon completion.
    ///
    private func showDebugMenu() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        let stackNavigator = UINavigationController()
        stackNavigator.navigationBar.prefersLargeTitles = true
        stackNavigator.modalPresentationStyle = .fullScreen
        let debugMenuCoordinator = module.makeDebugMenuCoordinator(stackNavigator: stackNavigator)
        debugMenuCoordinator.start()
        childCoordinator = debugMenuCoordinator

        rootNavigator?.rootViewController?.topmostViewController().present(
            stackNavigator,
            animated: true,
            completion: { feedbackGenerator.impactOccurred() },
        )
    }
    #endif
}

// MARK: - AuthCoordinatorDelegate

extension AppCoordinator: AuthCoordinatorDelegate {
    func didCompleteAuth() {
        showTab(route: .itemList(.list))
    }
}

// MARK: - HasErrorAlertServices

extension AppCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}

// MARK: - ItemListCoordinatorDelegate

extension AppCoordinator: ItemListCoordinatorDelegate {
    func switchToSettingsTab(route: SettingsRoute) {
        showTab(route: .settings(route))
    }
}
