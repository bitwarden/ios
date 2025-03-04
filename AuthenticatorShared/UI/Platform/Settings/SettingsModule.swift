// MARK: - SettingsModule

/// An object that builds coordinators for the settings tab.
///
@MainActor
protocol SettingsModule {
    /// Initializes a coordinator for navigating between `SettingsRoute`s.
    ///
    /// - Parameters:
    ///   - delegate: A delegate of the `SettingsCoordinator`.
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `SettingsRoute`s.
    ///
    func makeSettingsCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<SettingsRoute, SettingsEvent>
}

extension DefaultAppModule: SettingsModule {
    func makeSettingsCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<SettingsRoute, SettingsEvent> {
        SettingsCoordinator(
            module: self,
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
