// MARK: - FileSelectionModule

/// An object that builds coordinators for the file selection flow.
///
@MainActor
protocol FileSelectionModule {
    /// Initializes a coordinator for navigating between `FileSelectionRoutes`s.
    ///
    /// - Parameters
    ///   - delegate: The delegate for this coordinator.
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `FileSelectionRoutes`s.
    ///
    func makeFileSelectionCoordinator(
        delegate: FileSelectionDelegate,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<FileSelectionRoute>
}

extension DefaultAppModule: FileSelectionModule {
    func makeFileSelectionCoordinator(
        delegate: FileSelectionDelegate,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<FileSelectionRoute> {
        FileSelectionCoordinator(
            delegate: delegate,
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
