import BitwardenKit

// MARK: - AddEditFolderModule

/// An object that builds coordinators for the add and edit folder view.
///
@MainActor
protocol AddEditFolderModule {
    /// Initializes a coordinator for navigating between `AddEditFolderRoute`s.
    ///
    /// - Parameter stackNavigator: The stack navigator that will be used to navigate between routes.
    ///
    /// - Returns: A coordinator that can navigate to `AddEditFolderRoute`s.
    ///
    func makeAddEditFolderCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<AddEditFolderRoute, Void>
}

extension DefaultAppModule: AddEditFolderModule {
    func makeAddEditFolderCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<AddEditFolderRoute, Void> {
        AddEditFolderCoordinator(
            services: services,
            stackNavigator: stackNavigator,
        ).asAnyCoordinator()
    }
}
