import UIKit

// MARK: - TabModule

/// An object that builds coordinators for the tab interface.
///
public protocol TabModule: AnyObject {
    /// Initializes a coordinator for navigating to `TabRoute`s.
    ///
    /// - Parameter rootNavigator: The navigator used by the coordinator to navigate between routes.
    /// - Returns: A new coordinator that can navigate to any `TabRoute`.
    ///
    func makeTabCoordinator(
        rootNavigator: RootNavigator
    ) -> AnyCoordinator<TabRoute>
}

// MARK: - AppModule

extension DefaultAppModule: TabModule {
    public func makeTabCoordinator(
        rootNavigator: RootNavigator
    ) -> AnyCoordinator<TabRoute> {
        let tabController = UITabBarController()
        return TabCoordinator(
            rootNavigator: rootNavigator,
            tabNavigator: tabController
        ).asAnyCoordinator()
    }
}
