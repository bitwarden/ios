import Foundation

// MARK: - VaultModule

/// An object that builds coordinators for the vault tab.
@MainActor
protocol VaultModule {
    /// Initializes a coordinator for navigating between `VaultRoute`s.
    ///
    /// - Parameter stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `VaultRoute`s.
    ///
    func makeVaultCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<VaultRoute>
}

extension DefaultAppModule: VaultModule {
    func makeVaultCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<VaultRoute> {
        VaultCoordinator(
            module: self,
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
