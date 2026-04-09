import BitwardenKit

// MARK: - ImportLoginsModule

/// An object that builds coordinators for the import logins views.
///
@MainActor
protocol ImportLoginsModule {
    /// Initializes a coordinator for navigating between `ImportLoginsRoute`s.
    ///
    /// - Parameter stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `ImportLoginsRoute`s.
    ///
    func makeImportLoginsCoordinator(
        delegate: ImportLoginsCoordinatorDelegate,
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<ImportLoginsRoute, ImportLoginsEvent>
}

extension DefaultAppModule: ImportLoginsModule {
    func makeImportLoginsCoordinator(
        delegate: ImportLoginsCoordinatorDelegate,
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<ImportLoginsRoute, ImportLoginsEvent> {
        ImportLoginsCoordinator(
            delegate: delegate,
            module: self,
            services: services,
            stackNavigator: stackNavigator,
        ).asAnyCoordinator()
    }
}
