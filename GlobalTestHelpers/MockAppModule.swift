@testable import BitwardenShared

// MARK: - MockAppModule

class MockAppModule: AppModule, AuthModule, GeneratorModule, TabModule, SendModule, SettingsModule, VaultModule {
    var appCoordinator = MockCoordinator<AppRoute>()
    var authCoordinator = MockCoordinator<AuthRoute>()
    var generatorCoordinator = MockCoordinator<GeneratorRoute>()
    var sendCoordinator = MockCoordinator<SendRoute>()
    var settingsCoordinator = MockCoordinator<SettingsRoute>()
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

    func makeSendCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<SendRoute> {
        sendCoordinator.asAnyCoordinator()
    }

    func makeSettingsCoordinator(
        delegate: SettingsCoordinatorDelegate,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<SettingsRoute> {
        settingsCoordinator.asAnyCoordinator()
    }

    func makeTabCoordinator(
        rootNavigator: RootNavigator,
        settingsDelegate: SettingsCoordinatorDelegate,
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
