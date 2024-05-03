@testable import AuthenticatorShared

// MARK: - MockAppModule

class MockAppModule:
    AppModule,
    AuthModule,
    FileSelectionModule,
    ItemListModule,
    TutorialModule,
    TabModule {
    var appCoordinator = MockCoordinator<AppRoute, AppEvent>()
    var authCoordinator = MockCoordinator<AuthRoute, AuthEvent>()
    var authRouter = MockRouter<AuthEvent, AuthRoute>(routeForEvent: { _ in .vaultUnlock })
    var fileSelectionDelegate: FileSelectionDelegate?
    var fileSelectionCoordinator = MockCoordinator<FileSelectionRoute, Void>()
    var itemListCoordinator = MockCoordinator<ItemListRoute, ItemListEvent>()
    var tabCoordinator = MockCoordinator<TabRoute, Void>()
    var tutorialCoordinator = MockCoordinator<TutorialRoute, TutorialEvent>()

    func makeAppCoordinator(
        appContext _: AppContext,
        navigator _: RootNavigator
    ) -> AnyCoordinator<AppRoute, AppEvent> {
        appCoordinator.asAnyCoordinator()
    }

    func makeAuthCoordinator(
        delegate _: AuthCoordinatorDelegate,
        rootNavigator _: RootNavigator,
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<AuthRoute, AuthEvent> {
        authCoordinator.asAnyCoordinator()
    }

    func makeAuthRouter() -> AnyRouter<AuthEvent, AuthRoute> {
        authRouter.asAnyRouter()
    }

    func makeFileSelectionCoordinator(
        delegate: FileSelectionDelegate,
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<FileSelectionRoute, Void> {
        fileSelectionDelegate = delegate
        return fileSelectionCoordinator.asAnyCoordinator()
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
