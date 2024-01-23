@testable import BitwardenShared

// MARK: - MockAppModule

class MockAppModule:
    AppModule,
    AuthModule,
    ExtensionSetupModule,
    FileSelectionModule,
    GeneratorModule,
    TabModule,
    PasswordHistoryModule,
    SendModule,
    SendItemModule,
    SettingsModule,
    VaultModule,
    VaultItemModule {
    var appCoordinator = MockCoordinator<AppRoute>()
    var authCoordinator = MockCoordinator<AuthRoute>()
    var extensionSetupCoordinator = MockCoordinator<ExtensionSetupRoute>()
    var fileSelectionDelegate: FileSelectionDelegate?
    var fileSelectionCoordinator = MockCoordinator<FileSelectionRoute>()
    var generatorCoordinator = MockCoordinator<GeneratorRoute>()
    var passwordHistoryCoordinator = MockCoordinator<PasswordHistoryRoute>()
    var sendCoordinator = MockCoordinator<SendRoute>()
    var sendItemCoordinator = MockCoordinator<SendItemRoute>()
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

    func makeExtensionSetupCoordinator(
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<ExtensionSetupRoute> {
        extensionSetupCoordinator.asAnyCoordinator()
    }

    func makeFileSelectionCoordinator(
        delegate: FileSelectionDelegate,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<FileSelectionRoute> {
        fileSelectionDelegate = delegate
        return fileSelectionCoordinator.asAnyCoordinator()
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

    func makeSendItemCoordinator(
        delegate: SendItemDelegate,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<SendItemRoute> {
        sendItemCoordinator.asAnyCoordinator()
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
