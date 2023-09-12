import BitwardenShared

// MARK: - MockAppModule

class MockAppModule: AppModule, AuthModule {
    var appCoordinator = MockCoordinator<AppRoute>()
    var authCoordinator = MockCoordinator<AuthRoute>()

    func makeAppCoordinator(
        navigator: RootNavigator
    ) -> AnyCoordinator<AppRoute> {
        appCoordinator.asAnyCoordinator()
    }

    func makeAuthCoordinator(
        rootNavigator: RootNavigator,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<AuthRoute> {
        authCoordinator.asAnyCoordinator()
    }
}
