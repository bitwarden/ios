@testable import AuthenticatorShared

// MARK: - MockAppModule

class MockAppModule:
    AppModule,
    ItemListModule,
    TutorialModule,
    TabModule {
    var appCoordinator = MockCoordinator<AppRoute, AppEvent>()
    var itemListCoordinator = MockCoordinator<ItemListRoute, ItemListEvent>()
    var tabCoordinator = MockCoordinator<TabRoute, Void>()
    var tutorialCoordinator = MockCoordinator<TutorialRoute, TutorialEvent>()

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

    func makeTabCoordinator(
        errorReporter _: ErrorReporter,
        rootNavigator _: RootNavigator,
        tabNavigator _: TabNavigator
    ) -> AnyCoordinator<TabRoute, Void> {
        tabCoordinator.asAnyCoordinator()
    }

    func makeTutorialCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<TutorialRoute, TutorialEvent> {
        tutorialCoordinator.asAnyCoordinator()
    }
}
