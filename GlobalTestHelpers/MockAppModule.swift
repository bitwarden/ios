@testable import BitwardenShared

// MARK: - MockAppModule

class MockAppModule: AppModule, AuthModule, TabModule {
    var appCoordinator = MockCoordinator<AppRoute>()
    var authCoordinator = MockCoordinator<AuthRoute>()
    var tabCoordinator = MockCoordinator<TabRoute>()

    func makeAppCoordinator(
        navigator: RootNavigator
    ) -> AnyCoordinator<AppRoute> {
        appCoordinator.asAnyCoordinator()
    }

    func makeAuthCoordinator(
        delegate: AuthCoordinatorDelegate,
        rootNavigator: RootNavigator,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<AuthRoute> {
        authCoordinator.asAnyCoordinator()
    }

    func makeTabCoordinator(
        rootNavigator: RootNavigator
    ) -> AnyCoordinator<TabRoute> {
        tabCoordinator.asAnyCoordinator()
    }
}
