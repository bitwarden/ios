@testable import BitwardenShared

// MARK: - MockAppModule

class MockAppModule:
    AppModule,
    AuthModule,
    FileSelectionModule,
    GeneratorModule,
    TabModule,
    SendModule,
    SettingsModule,
    VaultModule,
    VaultItemModule {
    var appCoordinator = MockCoordinator<AppRoute>()
    var authCoordinator = MockCoordinator<AuthRoute>()
    var fileSelectionDelegate: FileSelectionDelegate?
    var fileSelectionCoordinator = MockCoordinator<FileSelectionRoute>()
    var generatorCoordinator = MockCoordinator<GeneratorRoute>()
    var sendCoordinator = MockCoordinator<SendRoute>()
    var settingsCoordinator = MockCoordinator<SettingsRoute>()
    var tabCoordinator = MockCoordinator<TabRoute>()
    var vaultCoordinator = MockCoordinator<VaultRoute>()
    var vaultItemCoordinator = MockCoordinator<VaultItemRoute>()

    func makeAppCoordinator(
        appContext: AppContext,
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

    func makeFileSelectionCoordinator(
        delegate: FileSelectionDelegate,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<FileSelectionRoute> {
        fileSelectionDelegate = delegate
        return fileSelectionCoordinator.asAnyCoordinator()
    }

    func makeGeneratorCoordinator(
        delegate: GeneratorCoordinatorDelegate?,
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
        rootNavigator: BitwardenShared.RootNavigator,
        settingsDelegate: BitwardenShared.SettingsCoordinatorDelegate,
        tabNavigator: BitwardenShared.TabNavigator,
        vaultDelegate: BitwardenShared.VaultCoordinatorDelegate
    ) -> BitwardenShared.AnyCoordinator<BitwardenShared.TabRoute> {
        tabCoordinator.asAnyCoordinator()
    }

    func makeVaultCoordinator(
        delegate: BitwardenShared.VaultCoordinatorDelegate,
        stackNavigator: BitwardenShared.StackNavigator
    ) -> BitwardenShared.AnyCoordinator<BitwardenShared.VaultRoute> {
        vaultCoordinator.asAnyCoordinator()
    }

    func makeVaultItemCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<VaultItemRoute> {
        vaultItemCoordinator.asAnyCoordinator()
    }
}
