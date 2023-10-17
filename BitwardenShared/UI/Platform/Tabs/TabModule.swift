import UIKit

// MARK: - TabModule

/// An object that builds coordinators for the tab interface.
///
public protocol TabModule: AnyObject {
    /// Initializes a coordinator for navigating to `TabRoute`s.
    ///
    /// - Parameter:
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - tabNavigator: The navigator used by the coordinator to navigate between routes.
    /// - Returns: A new coordinator that can navigate to any `TabRoute`.
    ///
    func makeTabCoordinator(
        rootNavigator: RootNavigator,
        tabNavigator: TabNavigator
    ) -> AnyCoordinator<TabRoute>
}

// MARK: - AppModule

extension DefaultAppModule: TabModule {
    public func makeTabCoordinator(
        rootNavigator: RootNavigator,
        tabNavigator: TabNavigator
    ) -> AnyCoordinator<TabRoute> {
        TabCoordinator(
            module: self,
            rootNavigator: rootNavigator,
            tabNavigator: tabNavigator
        ).asAnyCoordinator()
    }
}
