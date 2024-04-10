import Foundation

// MARK: - AuthenticatorItemModule

/// An object that builds coordinators for the token views.
@MainActor
protocol AuthenticatorItemModule {
    /// Initializes a coordinator for navigating between `AuthenticatorItemRoute` objects.
    ///
    /// - Parameter stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to a `AuthenticatorItemRoute`.
    ///
    func makeAuthenticatorItemCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<AuthenticatorItemRoute, AuthenticatorItemEvent>
}

extension DefaultAppModule: AuthenticatorItemModule {
    func makeAuthenticatorItemCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<AuthenticatorItemRoute, AuthenticatorItemEvent> {
        AuthenticatorItemCoordinator(
            module: self,
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
