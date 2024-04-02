import Foundation

// MARK: - ItemsModule

/// An object that builds coordinators for the Token List screen.
@MainActor
protocol ItemsModule {
    /// Initializes a coordinator for navigating between `ItemsRoute`s
    ///
    /// - Parameters:
    ///   - delegate: A delegate of the `ItemsCoordinator`.
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `ItemsRoute`s
    ///
    func makeItemsCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<ItemsRoute, ItemsEvent>
}

extension DefaultAppModule: ItemsModule {
    func makeItemsCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<ItemsRoute, ItemsEvent> {
        ItemsCoordinator(
            module: self,
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
