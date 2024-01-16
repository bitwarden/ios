@testable import BitwardenShared

// MARK: - MockAppModule

class MockAppModule:
    AppModule,
    AuthModule,
    GeneratorModule,
    TabModule,
    PasswordHistoryModule,
    SendModule,
    SettingsModule,
    VaultModule,
    VaultItemModule {
    var appCoordinator = MockCoordinator<AppRoute>()
    var authCoordinator = MockCoordinator<AuthRoute>()
    var generatorCoordinator = MockCoordinator<GeneratorRoute>()
    var passwordHistoryCoordinator = MockCoordinator<PasswordHistoryRoute>()
    var sendCoordinator = MockCoordinator<SendRoute>()
    var settingsCoordinator = MockCoordinator<SettingsRoute>()
    var tabCoordinator = MockCoordinator<TabRoute>()
    var vaultCoordinator = MockCoordinator<VaultRoute>()
    var vaultItemCoordinator = MockCoordinator<VaultItemRoute>()

    func makeAppCoordinator(
        appContext _: AppContext,
        navigator _: RootNavigator
    ) -> AnyCoordinator<AppRoute> {
        appCoordinator.asAnyCoordinator()
    }

    func makeAuthCoordinator(
        delegate _: AuthCoordinatorDelegate,
        rootNavigator _: RootNavigator,
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<AuthRoute> {
        authCoordinator.asAnyCoordinator()
    }

    func makeGeneratorCoordinator(
        delegate _: GeneratorCoordinatorDelegate?,
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<GeneratorRoute> {
        generatorCoordinator.asAnyCoordinator()
    }

    func makePasswordHistoryCoordinator(
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<PasswordHistoryRoute> {
        passwordHistoryCoordinator.asAnyCoordinator()
    }

    func makeSendCoordinator(
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<SendRoute> {
        sendCoordinator.asAnyCoordinator()
    }

    func makeSettingsCoordinator(
        delegate _: SettingsCoordinatorDelegate,
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<SettingsRoute> {
        settingsCoordinator.asAnyCoordinator()
    }

    func makeTabCoordinator(
        rootNavigator _: BitwardenShared.RootNavigator,
        settingsDelegate _: BitwardenShared.SettingsCoordinatorDelegate,
        tabNavigator _: BitwardenShared.TabNavigator,
        vaultDelegate _: BitwardenShared.VaultCoordinatorDelegate
    ) -> BitwardenShared.AnyCoordinator<BitwardenShared.TabRoute> {
        tabCoordinator.asAnyCoordinator()
    }

    func makeVaultCoordinator(
        delegate _: BitwardenShared.VaultCoordinatorDelegate,
        stackNavigator _: BitwardenShared.StackNavigator
    ) -> BitwardenShared.AnyCoordinator<BitwardenShared.VaultRoute> {
        vaultCoordinator.asAnyCoordinator()
    }

    func makeVaultItemCoordinator(
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<VaultItemRoute> {
        vaultItemCoordinator.asAnyCoordinator()
    }
}
