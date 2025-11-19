import BitwardenKit
import UIKit

// MARK: - TabModule

/// An object that builds coordinators for the tab interface.
///
@MainActor
protocol TabModule: AnyObject {
    /// Initializes a coordinator for navigating to `TabRoute`s.
    ///
    /// - Parameter:
    ///   - errorReporter: The error reporter used by the tab module.
    ///   - itemListDelegate: The delegate of the `ItemListCoordinator`.
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - tabNavigator: The navigator used by the coordinator to navigate between routes.
    /// - Returns: A new coordinator that can navigate to any `TabRoute`.
    ///
    func makeTabCoordinator(
        errorReporter: ErrorReporter,
        itemListDelegate: ItemListCoordinatorDelegate,
        rootNavigator: RootNavigator,
        tabNavigator: TabNavigator,
    ) -> AnyCoordinator<TabRoute, Void>
}

// MARK: - AppModule

extension DefaultAppModule: TabModule {
    func makeTabCoordinator(
        errorReporter: ErrorReporter,
        itemListDelegate: ItemListCoordinatorDelegate,
        rootNavigator: RootNavigator,
        tabNavigator: TabNavigator,
    ) -> AnyCoordinator<TabRoute, Void> {
        TabCoordinator(
            errorReporter: errorReporter,
            itemListDelegate: itemListDelegate,
            module: self,
            rootNavigator: rootNavigator,
            tabNavigator: tabNavigator,
        ).asAnyCoordinator()
    }
}
