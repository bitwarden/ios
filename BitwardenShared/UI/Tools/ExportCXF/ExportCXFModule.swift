import BitwardenKit

// MARK: - ExportCXFModule

/// An object that builds coordinators for the Credential Exchange export flow.
///
@MainActor
protocol ExportCXFModule {
    /// Initializes a coordinator for navigating between `ExportCXFRoute`s.
    ///
    /// - Parameters:
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `ExportCXFRoute`s.
    ///
    func makeExportCXFCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<ExportCXFRoute, Void>
}

extension DefaultAppModule: ExportCXFModule {
    func makeExportCXFCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<ExportCXFRoute, Void> {
        ExportCXFCoordinator(
            services: services,
            stackNavigator: stackNavigator,
        ).asAnyCoordinator()
    }
}
