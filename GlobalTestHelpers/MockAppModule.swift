@testable import BitwardenShared

// MARK: - MockAppModule

class MockAppModule: AppModule, AuthModule, GeneratorModule, TabModule, VaultModule {
    var appCoordinator = MockCoordinator<AppRoute>()
    var authCoordinator = MockCoordinator<AuthRoute>()
    var generatorCoordinator = MockCoordinator<GeneratorRoute>()
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

    func makeGeneratorCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<GeneratorRoute> {
        generatorCoordinator.asAnyCoordinator()
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
