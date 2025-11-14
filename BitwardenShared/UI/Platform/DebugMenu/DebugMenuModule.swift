import BitwardenKit
import Foundation

// MARK: - DebugMenuModule

/// An object that builds coordinator for the debug menu.
@MainActor
protocol DebugMenuModule {
    /// Initializes a coordinator for navigating between `DebugMenuRoute`s.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for the debug menu coordinator.
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `DebugMenuRoute`s.
    ///
    func makeDebugMenuCoordinator(
        delegate: DebugMenuCoordinatorDelegate,
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<DebugMenuRoute, Void>
}

extension DefaultAppModule: DebugMenuModule {
    func makeDebugMenuCoordinator(
        delegate: DebugMenuCoordinatorDelegate,
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<DebugMenuRoute, Void> {
        DebugMenuCoordinator(
            delegate: delegate,
            services: services,
            stackNavigator: stackNavigator,
        )
        .asAnyCoordinator()
    }
}
