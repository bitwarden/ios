@testable import AuthenticatorShared

// MARK: - MockAppModule

class MockAppModule:
    AppModule,
    ItemsModule {
    var appCoordinator = MockCoordinator<AppRoute, AppEvent>()
    var itemsCoordinator = MockCoordinator<ItemsRoute, ItemsEvent>()

    func makeAppCoordinator(
        appContext _: AppContext,
        navigator _: RootNavigator
    ) -> AnyCoordinator<AppRoute, AppEvent> {
        appCoordinator.asAnyCoordinator()
    }

    func makeItemsCoordinator(
        stackNavigator _: AuthenticatorShared.StackNavigator
    ) -> AnyCoordinator<ItemsRoute, ItemsEvent> {
        itemsCoordinator.asAnyCoordinator()
    }
}
