import SwiftUI
import UIKit

// MARK: - TabCoordinator

/// A coordinator that manages navigation in the tab interface.
///
internal final class TabCoordinator: Coordinator {
    // MARK: Types

    /// The module types required by this coordinator for creating child coordinators.
    typealias Module = SettingsModule
        & VaultModule

    // MARK: Properties

    /// The root navigator used to display this coordinator's interface.
    weak var rootNavigator: (any RootNavigator)?

    /// The tab navigator that is managed by this coordinator.
    var tabNavigator: TabNavigator

    // MARK: Private Properties

    /// The module used to create child coordinators.
    private let module: Module

    /// The coordinator used to navigate to `SettingsRoute`s.
    private var settingsCoordinator: AnyCoordinator<SettingsRoute>?

    /// A delegate of the `SettingsCoordinator`.
    private weak var settingsDelegate: SettingsCoordinatorDelegate?

    /// The coordinator used to navigate to `VaultRoute`s.
    private var vaultCoordinator: AnyCoordinator<VaultRoute>?

    // MARK: Initialization

    /// Creates a new `TabCoordinator`.
    ///
    /// - Parameters:
    ///   - module: The module used to create child coordinators.
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - settingsDelegate: A delegate of the `SettingsCoordinator`.
    ///   - tabNavigator: The tab navigator that is managed by this coordinator.
    ///
    init(
        module: Module,
        rootNavigator: RootNavigator,
        settingsDelegate: SettingsCoordinatorDelegate,
        tabNavigator: TabNavigator
    ) {
        self.module = module
        self.rootNavigator = rootNavigator
        self.settingsDelegate = settingsDelegate
        self.tabNavigator = tabNavigator
    }

    // MARK: Methods

    func hideLoadingOverlay() {
        tabNavigator.hideLoadingOverlay()
    }

    func navigate(to route: TabRoute, context: AnyObject?) {
        tabNavigator.selectedIndex = route.index
        switch route {
        case let .vault(vaultRoute):
            show(vaultRoute: vaultRoute, context: context)
        case .send:
            // TODO: BIT-249 Add show send function for navigating to a send route
            break
        case .generator:
            // TODO: BIT-327 Add show generation function for navigation to a generator route
            break
        case let .settings(settingsRoute):
            settingsCoordinator?.navigate(to: settingsRoute, context: context)
        }
    }

    func show(vaultRoute: VaultRoute, context: AnyObject?) {
        vaultCoordinator?.navigate(to: vaultRoute, context: context)
    }

    func showLoadingOverlay(_ state: LoadingOverlayState) {
        tabNavigator.showLoadingOverlay(state)
    }

    func start() {
        guard let rootNavigator, let settingsDelegate else { return }

        rootNavigator.show(child: tabNavigator)

        let vaultNavigator = UINavigationController()
        vaultNavigator.navigationBar.prefersLargeTitles = true
        vaultCoordinator = module.makeVaultCoordinator(
            stackNavigator: vaultNavigator
        )

        let sendNavigator = UINavigationController()
        sendNavigator.push(Text("Send"))

        let generatorNavigator = UINavigationController()
        generatorNavigator.push(Text("Generator"))

        let settingsNavigator = UINavigationController()
        settingsNavigator.navigationBar.prefersLargeTitles = true
        settingsCoordinator = module.makeSettingsCoordinator(
            delegate: settingsDelegate,
            stackNavigator: settingsNavigator
        )
        settingsCoordinator?.start()

        let tabsAndNavigators: [TabRoute: Navigator] = [
            .vault(.list): vaultNavigator,
            .send: sendNavigator,
            .generator: generatorNavigator,
            .settings(.settings): settingsNavigator,
        ]
        tabNavigator.setNavigators(tabsAndNavigators)
    }
}
