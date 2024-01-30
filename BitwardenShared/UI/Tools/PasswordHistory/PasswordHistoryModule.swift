// MARK: - PasswordHistoryModule

/// An object that builds coordinators for the password history view.
///
@MainActor
protocol PasswordHistoryModule {
    /// Initializes a coordinator for navigating between `PasswordHistoryRoute`s.
    ///
    /// - Parameter stackNavigator: The stack navigator that will be used to navigate between routes.
    ///
    /// - Returns: A coordinator that can navigate to `PasswordHistoryRoute`s.
    ///
    func makePasswordHistoryCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<PasswordHistoryRoute, Void>
}

extension DefaultAppModule: PasswordHistoryModule {
    func makePasswordHistoryCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<PasswordHistoryRoute, Void> {
        PasswordHistoryCoordinator(
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
