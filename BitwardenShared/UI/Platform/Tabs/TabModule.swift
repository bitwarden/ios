import UIKit

// MARK: - TabModule

/// An object that builds coordinators for the tab interface.
///
public protocol TabModule: AnyObject {
    /// Initializes a coordinator for navigating to `TabRoute`s.
    ///
    /// - Parameter:
    ///   - errorReporter: The error reporter used by the tab module.
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - settingsDelegate: The delegate for the settings coordinator.
    ///   - tabNavigator: The navigator used by the coordinator to navigate between routes.
    ///   - vaultDelegate: The delegate for the vault coordinator.
    ///   - vaultRepository: The vault repository used by the tab module.
    /// - Returns: A new coordinator that can navigate to any `TabRoute`.
    ///
    func makeTabCoordinator( // swiftlint:disable:this function_parameter_count
        errorReporter: ErrorReporter,
        rootNavigator: RootNavigator,
        settingsDelegate: SettingsCoordinatorDelegate,
        tabNavigator: TabNavigator,
        vaultDelegate: VaultCoordinatorDelegate,
        vaultRepository: VaultRepository
    ) -> AnyCoordinator<TabRoute, Void>
}

// MARK: - AppModule

extension DefaultAppModule: TabModule {
    public func makeTabCoordinator( // swiftlint:disable:this function_parameter_count
        errorReporter: ErrorReporter,
        rootNavigator: RootNavigator,
        settingsDelegate: SettingsCoordinatorDelegate,
        tabNavigator: TabNavigator,
        vaultDelegate: VaultCoordinatorDelegate,
        vaultRepository: VaultRepository
    ) -> AnyCoordinator<TabRoute, Void> {
        TabCoordinator(
            errorReporter: errorReporter,
            module: self,
            rootNavigator: rootNavigator,
            settingsDelegate: settingsDelegate,
            tabNavigator: tabNavigator,
            vaultDelegate: vaultDelegate,
            vaultRepository: vaultRepository
        ).asAnyCoordinator()
    }
}
