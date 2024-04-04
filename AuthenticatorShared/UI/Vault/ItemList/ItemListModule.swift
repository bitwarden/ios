import Foundation

// MARK: - ItemListModule

/// An object that builds coordinators for the Token List screen.
@MainActor
protocol ItemListModule {
    /// Initializes a coordinator for navigating between `ItemListRoute` objects
    ///
    /// - Parameters:
    ///   - delegate: A delegate of the `ItemListCoordinator`.
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to an `ItemListRoute`
    ///
    func makeItemListCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<ItemListRoute, ItemListEvent>
}

extension DefaultAppModule: ItemListModule {
    func makeItemListCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<ItemListRoute, ItemListEvent> {
        ItemListCoordinator(
            module: self,
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
