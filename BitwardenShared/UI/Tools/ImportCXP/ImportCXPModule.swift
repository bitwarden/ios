// MARK: - ImportCXPModule

/// An object that builds coordinators for the Credential Exchange import flow.
///
@MainActor
protocol ImportCXPModule {
    /// Initializes a coordinator for navigating between `ImportCXPRoute`s.
    ///
    /// - Parameters:
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `ImportCXPRoute`s.
    ///
    func makeImportCXPCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<ImportCXPRoute, Void>
}

extension DefaultAppModule: ImportCXPModule {
    func makeImportCXPCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<ImportCXPRoute, Void> {
        ImportCXPCoordinator(
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
