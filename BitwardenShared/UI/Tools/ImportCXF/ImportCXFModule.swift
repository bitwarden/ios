import BitwardenKit

// MARK: - ImportCXFModule

/// An object that builds coordinators for the Credential Exchange import flow.
///
@MainActor
protocol ImportCXFModule {
    /// Initializes a coordinator for navigating between `ImportCXFRoute`s.
    ///
    /// - Parameters:
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `ImportCXFRoute`s.
    ///
    func makeImportCXFCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<ImportCXFRoute, Void>
}

extension DefaultAppModule: ImportCXFModule {
    func makeImportCXFCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<ImportCXFRoute, Void> {
        ImportCXFCoordinator(
            services: services,
            stackNavigator: stackNavigator,
        ).asAnyCoordinator()
    }
}
