import Foundation

// MARK: - VaultModule

/// An object that builds coordinators for the vault item views.
@MainActor
protocol VaultItemModule {
    /// Initializes a coordinator for navigating between `VaultItemRoute`s.
    ///
    /// - Parameter stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `VaultItemRoute`s.
    ///
    func makeVaultItemCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<VaultItemRoute>
}

extension DefaultAppModule: VaultItemModule {
    func makeVaultItemCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<VaultItemRoute> {
        VaultItemCoordinator(
            module: self,
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
