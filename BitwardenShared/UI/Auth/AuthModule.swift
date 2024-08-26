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
    ) -> AnyCoordinator<AuthRoute, AuthEvent>

    /// Initializes a router for converting AuthEvents into AuthRoutes.
    ///
    /// - Returns: A router that can convert `AuthEvent`s into `AuthRoute`s.
    ///
    func makeAuthRouter() -> AnyRouter<AuthEvent, AuthRoute>
}

// MARK: - DefaultAppModule

extension DefaultAppModule: AuthModule {
    func makeAuthCoordinator(
        delegate: AuthCoordinatorDelegate,
        rootNavigator: RootNavigator,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<AuthRoute, AuthEvent> {
        AuthCoordinator(
            appExtensionDelegate: appExtensionDelegate,
            delegate: delegate,
            rootNavigator: rootNavigator,
            router: makeAuthRouter(),
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }

    func makeAuthRouter() -> AnyRouter<AuthEvent, AuthRoute> {
        AuthRouter(
            isInAppExtension: appExtensionDelegate != nil,
            services: services
        ).asAnyRouter()
    }
}
