import SwiftUI
import UIKit

// MARK: - TabCoordinator

/// A coordinator that manages navigation in the tab interface.
///
internal final class TabCoordinator: Coordinator {
    // MARK: Types

    /// The module types required by this coordinator for creating child coordinators.
    typealias Module = VaultModule

    // MARK: Properties

    /// The root navigator used to display this coordinator's interface.
    weak var rootNavigator: (any RootNavigator)?

    /// The tab navigator that is managed by this coordinator.
    var tabNavigator: TabNavigator

    // MARK: Private Properties

    /// The module used to create child coordinators.
    private let module: Module

    /// The coordinator used to navigate to `VaultRoute`s.
    private var vaultCoordinator: AnyCoordinator<VaultRoute>?

    // MARK: Initialization

    /// Creates a new `TabCoordinator`.
    ///
    /// - Parameters:
    ///   - module: The module used to create child coordinators.
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - tabNavigator: The tab navigator that is managed by this coordinator.
    ///
    init(
        module: Module,
        rootNavigator: RootNavigator,
        tabNavigator: TabNavigator
    ) {
        self.module = module
        self.rootNavigator = rootNavigator
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
        case .settings:
            // TODO: BIT-86 Add show settings function for navigating to a settings route
            break
        }
    }

    func show(vaultRoute: VaultRoute, context: AnyObject?) {
        vaultCoordinator?.navigate(to: vaultRoute, context: context)
    }

    func showLoadingOverlay(_ state: LoadingOverlayState) {
        tabNavigator.showLoadingOverlay(state)
    }

    func start() {
        guard let rootNavigator else { return }

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
        settingsNavigator.push(Text("Settings"))

        let tabsAndNavigators: [TabRoute: Navigator] = [
            .vault(.list): vaultNavigator,
            .send: sendNavigator,
            .generator: generatorNavigator,
            .settings: settingsNavigator,
        ]
        tabNavigator.setNavigators(tabsAndNavigators)
    }
}
