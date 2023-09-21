import UIKit

// MARK: - AuthModule

/// An object that builds coordinators for the auth flow.
@MainActor
protocol AuthModule {
    /// Initializes a coordinator for navigating between `AuthRoute`s.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for this coordinator.
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `AuthRoute`s.
    ///
    func makeAuthCoordinator(
        delegate: AuthCoordinatorDelegate,
        rootNavigator: RootNavigator,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<AuthRoute>
}

// MARK: - DefaultAppModule

extension DefaultAppModule: AuthModule {
    func makeAuthCoordinator(
        delegate: AuthCoordinatorDelegate,
        rootNavigator: RootNavigator,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<AuthRoute> {
        AuthCoordinator(
            delegate: delegate,
            rootNavigator: rootNavigator,
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
