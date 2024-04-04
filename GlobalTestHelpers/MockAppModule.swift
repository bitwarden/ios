@testable import AuthenticatorShared

// MARK: - MockAppModule

class MockAppModule:
    AppModule,
    ItemListModule {
    var appCoordinator = MockCoordinator<AppRoute, AppEvent>()
    var itemListCoordinator = MockCoordinator<ItemListRoute, ItemListEvent>()

    func makeAppCoordinator(
        appContext _: AppContext,
        navigator _: RootNavigator
    ) -> AnyCoordinator<AppRoute, AppEvent> {
        appCoordinator.asAnyCoordinator()
    }

    func makeItemListCoordinator(
        stackNavigator _: AuthenticatorShared.StackNavigator
    ) -> AnyCoordinator<ItemListRoute, ItemListEvent> {
        itemListCoordinator.asAnyCoordinator()
    }
}
