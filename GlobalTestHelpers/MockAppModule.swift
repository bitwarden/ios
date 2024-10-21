@testable import BitwardenShared

// MARK: - MockAppModule

class MockAppModule:
    AppModule,
    AuthModule,
    DebugMenuModule,
    ExtensionSetupModule,
    FileSelectionModule,
    GeneratorModule,
    LoginRequestModule,
    PasswordHistoryModule,
    SendModule,
    SendItemModule,
    SettingsModule,
    TabModule,
    VaultModule,
    VaultItemModule {
    var appCoordinator = MockCoordinator<AppRoute, AppEvent>()
    var authCoordinator = MockCoordinator<AuthRoute, AuthEvent>()
    var authRouter = MockRouter<AuthEvent, AuthRoute>(routeForEvent: { _ in .landing })
    var debugMenuCoordinator = MockCoordinator<DebugMenuRoute, Void>()
    var extensionSetupCoordinator = MockCoordinator<ExtensionSetupRoute, Void>()
    var fileSelectionDelegate: FileSelectionDelegate?
    var fileSelectionCoordinator = MockCoordinator<FileSelectionRoute, Void>()
    var generatorCoordinator = MockCoordinator<GeneratorRoute, Void>()
    var loginRequestCoordinator = MockCoordinator<LoginRequestRoute, Void>()
    var passwordHistoryCoordinator = MockCoordinator<PasswordHistoryRoute, Void>()
    var sendCoordinator = MockCoordinator<SendRoute, Void>()
    var sendItemCoordinator = MockCoordinator<SendItemRoute, AuthAction>()
    var settingsCoordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
    var settingsNavigator: StackNavigator? // swiftlint:disable:this weak_navigator
    var tabCoordinator = MockCoordinator<TabRoute, Void>()
    var vaultCoordinator = MockCoordinator<VaultRoute, AuthAction>()
    var vaultItemCoordinator = MockCoordinator<VaultItemRoute, VaultItemEvent>()

    func makeAppCoordinator(
        appContext _: AppContext,
        navigator _: RootNavigator
    ) -> AnyCoordinator<AppRoute, AppEvent> {
        appCoordinator.asAnyCoordinator()
    }

    func makeAuthCoordinator(
        delegate _: AuthCoordinatorDelegate?,
        rootNavigator _: RootNavigator?,
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<AuthRoute, AuthEvent> {
        authCoordinator.asAnyCoordinator()
    }

    func makeAuthRouter() -> BitwardenShared.AnyRouter<BitwardenShared.AuthEvent, BitwardenShared.AuthRoute> {
        authRouter.asAnyRouter()
    }

    func makeDebugMenuCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<DebugMenuRoute, Void> {
        debugMenuCoordinator.asAnyCoordinator()
    }

    func makeExtensionSetupCoordinator(
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<ExtensionSetupRoute, Void> {
        extensionSetupCoordinator.asAnyCoordinator()
    }

    func makeFileSelectionCoordinator(
        delegate: FileSelectionDelegate,
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<FileSelectionRoute, Void> {
        fileSelectionDelegate = delegate
        return fileSelectionCoordinator.asAnyCoordinator()
    }

    func makeGeneratorCoordinator(
        delegate _: GeneratorCoordinatorDelegate?,
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<GeneratorRoute, Void> {
        generatorCoordinator.asAnyCoordinator()
    }

    func makeLoginRequestCoordinator(
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<LoginRequestRoute, Void> {
        loginRequestCoordinator.asAnyCoordinator()
    }

    func makePasswordHistoryCoordinator(
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<PasswordHistoryRoute, Void> {
        passwordHistoryCoordinator.asAnyCoordinator()
    }

    func makeSendCoordinator(
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<SendRoute, Void> {
        sendCoordinator.asAnyCoordinator()
    }

    func makeSendItemCoordinator(
        delegate _: SendItemDelegate,
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<SendItemRoute, AuthAction> {
        sendItemCoordinator.asAnyCoordinator()
    }

    func makeSettingsCoordinator(
        delegate _: SettingsCoordinatorDelegate,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<SettingsRoute, SettingsEvent> {
        settingsNavigator = stackNavigator
        return settingsCoordinator.asAnyCoordinator()
    }

    func makeTabCoordinator( // swiftlint:disable:this function_parameter_count
        errorReporter _: BitwardenShared.ErrorReporter,
        rootNavigator _: BitwardenShared.RootNavigator,
        settingsDelegate _: BitwardenShared.SettingsCoordinatorDelegate,
        tabNavigator _: BitwardenShared.TabNavigator,
        vaultDelegate _: BitwardenShared.VaultCoordinatorDelegate,
        vaultRepository _: BitwardenShared.VaultRepository
    ) -> BitwardenShared.AnyCoordinator<BitwardenShared.TabRoute, Void> {
        tabCoordinator.asAnyCoordinator()
    }

    func makeVaultCoordinator(
        delegate _: BitwardenShared.VaultCoordinatorDelegate,
        stackNavigator _: BitwardenShared.StackNavigator
    ) -> BitwardenShared.AnyCoordinator<BitwardenShared.VaultRoute, AuthAction> {
        vaultCoordinator.asAnyCoordinator()
    }

    func makeVaultItemCoordinator(
        stackNavigator _: StackNavigator
    ) -> AnyCoordinator<VaultItemRoute, VaultItemEvent> {
        vaultItemCoordinator.asAnyCoordinator()
    }
}
