import Foundation

// MARK: - LoginRequestModule

/// An object that builds coordinators for the vault tab.
@MainActor
protocol LoginRequestModule {
    /// Initializes a coordinator for navigating between `LoginRequestRoute`s.
    ///
    /// - Parameters:
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `LoginRequestRoute`s.
    ///
    func makeLoginRequestCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<LoginRequestRoute>
}

extension DefaultAppModule: LoginRequestModule {
    func makeLoginRequestCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<LoginRequestRoute> {
        LoginRequestCoordinator(
            services: services,
            stackNavigator: stackNavigator
        )
        .asAnyCoordinator()
    }
}
