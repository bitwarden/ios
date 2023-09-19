import SwiftUI
import UIKit

// MARK: - TabCoordinator

/// A coordinator that manages navigation in the tab interface.
///
internal final class TabCoordinator: Coordinator {
    // MARK: Properties

    /// The root navigator used to display this coordinator's interface.
    weak var rootNavigator: (any RootNavigator)?

    /// The tab navigator that is managed by this coordinator.
    var tabNavigator: TabNavigator

    // MARK: Initialization

    /// Creates a new `TabCoordinator`.
    ///
    /// - Parameters:
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - tabNavigator: The tab navigator that is managed by this coordinator.
    ///
    init(
        rootNavigator: RootNavigator,
        tabNavigator: TabNavigator
    ) {
        self.rootNavigator = rootNavigator
        self.tabNavigator = tabNavigator
    }

    // MARK: Methods

    func navigate(to route: TabRoute, context: AnyObject?) {
        tabNavigator.selectedIndex = route.rawValue
    }

    func start() {
        guard let rootNavigator else { return }

        rootNavigator.show(child: tabNavigator)

        let vaultNavigator = UINavigationController()
        vaultNavigator.push(Text("My Vault"))

        let sendNavigator = UINavigationController()
        sendNavigator.push(Text("Send"))

        let generatorNavigator = UINavigationController()
        generatorNavigator.push(Text("Generator"))

        let settingsNavigator = UINavigationController()
        settingsNavigator.push(Text("Settings"))

        let tabsAndNavigators: [TabRoute: Navigator] = [
            .vault: vaultNavigator,
            .send: sendNavigator,
            .generator: generatorNavigator,
            .settings: settingsNavigator,
        ]
        tabNavigator.setNavigators(tabsAndNavigators)
    }
}
