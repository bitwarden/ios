// MARK: - Generator Module

/// An object that builds coordinators for the generator tab.
///
@MainActor
protocol GeneratorModule {
    /// Initializes a coordinator for navigating between `GeneratorRoute`s.
    ///
    /// - Parameters:
    ///   - delegate: An optional delegate for the coordinator.
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `GeneratorRoute`s.
    ///
    func makeGeneratorCoordinator(
        delegate: GeneratorCoordinatorDelegate?,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<GeneratorRoute>
}

extension DefaultAppModule: GeneratorModule {
    func makeGeneratorCoordinator(
        delegate: GeneratorCoordinatorDelegate?,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<GeneratorRoute> {
        GeneratorCoordinator(
            delegate: delegate,
            module: self,
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
