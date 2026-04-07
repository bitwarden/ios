import BitwardenKit

// MARK: - FolderSelectionModule

/// An object that builds coordinators for the folder selection flow.
///
@MainActor
protocol FolderSelectionModule {
    /// Initializes a coordinator for folder selection.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for this coordinator.
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A `FolderSelectionCoordinator` that manages folder selection.
    ///
    func makeFolderSelectionCoordinator(
        delegate: FolderSelectionDelegate,
        stackNavigator: StackNavigator,
    ) -> FolderSelectionCoordinator
}

extension DefaultAppModule: FolderSelectionModule {
    func makeFolderSelectionCoordinator(
        delegate: FolderSelectionDelegate,
        stackNavigator: StackNavigator,
    ) -> FolderSelectionCoordinator {
        FolderSelectionCoordinator(
            delegate: delegate,
            services: services,
            stackNavigator: stackNavigator,
        )
    }
}
