import UIKit

// MARK: - TabModule

/// An object that builds coordinators for the tab interface.
///
public protocol TabModule: AnyObject {
    /// Initializes a coordinator for navigating to `TabRoute`s.
    ///
    /// - Parameter:
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - settingsDelegate: The delegate for the settings coordinator.
    ///   - tabNavigator: The navigator used by the coordinator to navigate between routes.
    ///   - vaultDelegate: The delegate for the vault coordinator.
    /// - Returns: A new coordinator that can navigate to any `TabRoute`.
    ///
    func makeTabCoordinator(
        rootNavigator: RootNavigator,
        settingsDelegate: SettingsCoordinatorDelegate,
        tabNavigator: TabNavigator,
        vaultDelegate: VaultCoordinatorDelegate
    ) -> AnyCoordinator<TabRoute, Void>
}

// MARK: - AppModule

extension DefaultAppModule: TabModule {
    public func makeTabCoordinator(
        rootNavigator: RootNavigator,
        settingsDelegate: SettingsCoordinatorDelegate,
        tabNavigator: TabNavigator,
        vaultDelegate: VaultCoordinatorDelegate
    ) -> AnyCoordinator<TabRoute, Void> {
        TabCoordinator(
            module: self,
            rootNavigator: rootNavigator,
            settingsDelegate: settingsDelegate,
            tabNavigator: tabNavigator,
            vaultDelegate: vaultDelegate
        ).asAnyCoordinator()
    }
}
