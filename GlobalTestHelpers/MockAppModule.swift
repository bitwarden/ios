@testable import BitwardenShared

// MARK: - MockAppModule

class MockAppModule: AppModule, AuthModule, TabModule, VaultModule {
    var appCoordinator = MockCoordinator<AppRoute>()
    var authCoordinator = MockCoordinator<AuthRoute>()
    var tabCoordinator = MockCoordinator<TabRoute>()
    var vaultCoordinator = MockCoordinator<VaultRoute>()

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
        rootNavigator: RootNavigator,
        tabNavigator: TabNavigator
    ) -> AnyCoordinator<TabRoute> {
        tabCoordinator.asAnyCoordinator()
    }

    func makeVaultCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<VaultRoute> {
        vaultCoordinator.asAnyCoordinator()
    }
}
