// MARK: - Generator Module

/// An object that builds coordinators for the generator tab.
///
@MainActor
protocol GeneratorModule {
    /// Initializes a coordinator for navigating between `GeneratorRoute`s.
    ///
    /// - Parameter stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `GeneratorRoute`s.
    ///
    func makeGeneratorCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<GeneratorRoute>
}

extension DefaultAppModule: GeneratorModule {
    func makeGeneratorCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<GeneratorRoute> {
        GeneratorCoordinator(
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
