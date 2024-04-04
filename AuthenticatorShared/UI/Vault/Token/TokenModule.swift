import Foundation

// MARK: - TokenModule

/// An object that builds coordinators for the token views.
@MainActor
protocol TokenModule {
    /// Initializes a coordinator for navigating between `TokenRoute` objects.
    ///
    /// - Parameter stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to a `TokenRoute`.
    ///
    func makeTokenCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<TokenRoute, TokenEvent>
}

extension DefaultAppModule: TokenModule {
    func makeTokenCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<TokenRoute, TokenEvent> {
        TokenCoordinator(
            module: self,
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
