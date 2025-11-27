import BitwardenKit
import BitwardenKitMocks
import UIKit

@testable import BitwardenShared

// MARK: - MockAppModule

class MockAppModule:
    AddEditFolderModule,
    AppModule,
    AuthModule,
    DebugMenuModule,
    ExportCXFModule,
    ExtensionSetupModule,
    FileSelectionModule,
    FlightRecorderModule,
    GeneratorModule,
    ImportCXFModule,
    ImportLoginsModule,
    LoginRequestModule,
    NavigatorBuilderModule,
    PasswordAutoFillModule,
    PasswordHistoryModule,
    ProfileSwitcherModule,
    SelectLanguageModule,
    SendModule,
    SendItemModule,
    SettingsModule,
    TabModule,
    VaultModule,
    VaultItemModule {
    var addEditFolderCoordinator = MockCoordinator<AddEditFolderRoute, Void>()
    var appCoordinator = MockCoordinator<AppRoute, AppEvent>()
    var authCoordinator = MockCoordinator<AuthRoute, AuthEvent>()
    var authRouter = MockRouter<AuthEvent, AuthRoute>(routeForEvent: { _ in .landing })
    var debugMenuCoordinator = MockCoordinator<DebugMenuRoute, Void>()
    var debugMenuCoordinatorDelegate: DebugMenuCoordinatorDelegate?
    var exportCXFCoordinator = MockCoordinator<ExportCXFRoute, Void>()
    var extensionSetupCoordinator = MockCoordinator<ExtensionSetupRoute, Void>()
    var fileSelectionDelegate: FileSelectionDelegate?
    var fileSelectionCoordinator = MockCoordinator<FileSelectionRoute, Void>()
    var flightRecorderCoordinator = MockCoordinator<FlightRecorderRoute, Void>()
    var generatorCoordinator = MockCoordinator<GeneratorRoute, Void>()
    var importCXFCoordinator = MockCoordinator<ImportCXFRoute, Void>()
    var importLoginsCoordinator = MockCoordinator<ImportLoginsRoute, ImportLoginsEvent>()
    var loginRequestCoordinator = MockCoordinator<LoginRequestRoute, Void>()
    var passwordAutoFillCoordinator = MockCoordinator<PasswordAutofillRoute, PasswordAutofillEvent>()
    var passwordAutoFillCoordinatorDelegate: PasswordAutoFillCoordinatorDelegate?
    // swiftlint:disable:next weak_navigator identifier_name
    var passwordAutoFillCoordinatorStackNavigator: StackNavigator?
    var passwordHistoryCoordinator = MockCoordinator<PasswordHistoryRoute, Void>()
    var profileSwitcherCoordinator = MockCoordinator<ProfileSwitcherRoute, Void>()
    var selectLanguageCoordinator = MockCoordinator<SelectLanguageRoute, Void>()
    // swiftlint:disable:next weak_navigator identifier_name
    var selectLanguageCoordinatorStackNavigator: StackNavigator?
    var sendCoordinator = MockCoordinator<SendRoute, Void>()
    var sendItemCoordinator = MockCoordinator<SendItemRoute, AuthAction>()
    var settingsCoordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
    var settingsNavigator: StackNavigator? // swiftlint:disable:this weak_navigator
    var tabCoordinator = MockCoordinator<TabRoute, Void>()
    var vaultCoordinator = MockCoordinator<VaultRoute, AuthAction>()
    var vaultItemCoordinator = MockCoordinator<VaultItemRoute, VaultItemEvent>()

    func makeAddEditFolderCoordinator(
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<AddEditFolderRoute, Void> {
        addEditFolderCoordinator.asAnyCoordinator()
    }

    func makeAppCoordinator(
        appContext _: AppContext,
        navigator _: RootNavigator,
    ) -> AnyCoordinator<AppRoute, AppEvent> {
        appCoordinator.asAnyCoordinator()
    }

    func makeAuthCoordinator(
        delegate _: AuthCoordinatorDelegate?,
        rootNavigator _: RootNavigator?,
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<AuthRoute, AuthEvent> {
        authCoordinator.asAnyCoordinator()
    }

    func makeAuthRouter() -> AnyRouter<AuthEvent, AuthRoute> {
        authRouter.asAnyRouter()
    }

    func makeDebugMenuCoordinator(
        delegate: DebugMenuCoordinatorDelegate,
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<DebugMenuRoute, Void> {
        debugMenuCoordinatorDelegate = delegate
        return debugMenuCoordinator.asAnyCoordinator()
    }

    func makeExportCXFCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<ExportCXFRoute, Void> {
        exportCXFCoordinator.asAnyCoordinator()
    }

    func makeExtensionSetupCoordinator(
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<ExtensionSetupRoute, Void> {
        extensionSetupCoordinator.asAnyCoordinator()
    }

    func makeFileSelectionCoordinator(
        delegate: FileSelectionDelegate,
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<FileSelectionRoute, Void> {
        fileSelectionDelegate = delegate
        return fileSelectionCoordinator.asAnyCoordinator()
    }

    func makeFlightRecorderCoordinator(
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<FlightRecorderRoute, Void> {
        flightRecorderCoordinator.asAnyCoordinator()
    }

    func makeGeneratorCoordinator(
        delegate _: GeneratorCoordinatorDelegate?,
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<GeneratorRoute, Void> {
        generatorCoordinator.asAnyCoordinator()
    }

    func makeImportCXFCoordinator(
        stackNavigator: any StackNavigator,
    ) -> AnyCoordinator<ImportCXFRoute, Void> {
        importCXFCoordinator.asAnyCoordinator()
    }

    func makeImportLoginsCoordinator(
        delegate: any ImportLoginsCoordinatorDelegate,
        stackNavigator: any StackNavigator,
    ) -> AnyCoordinator<ImportLoginsRoute, ImportLoginsEvent> {
        importLoginsCoordinator.asAnyCoordinator()
    }

    func makeLoginRequestCoordinator(
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<LoginRequestRoute, Void> {
        loginRequestCoordinator.asAnyCoordinator()
    }

    func makeNavigationController() -> UINavigationController {
        UINavigationController()
    }

    func makePasswordAutoFillCoordinator(
        delegate: PasswordAutoFillCoordinatorDelegate?,
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<PasswordAutofillRoute, PasswordAutofillEvent> {
        passwordAutoFillCoordinatorDelegate = delegate
        passwordAutoFillCoordinatorStackNavigator = stackNavigator
        return passwordAutoFillCoordinator.asAnyCoordinator()
    }

    func makePasswordHistoryCoordinator(
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<PasswordHistoryRoute, Void> {
        passwordHistoryCoordinator.asAnyCoordinator()
    }

    func makeProfileSwitcherCoordinator(
        handler: any ProfileSwitcherHandler,
        stackNavigator: any StackNavigator,
    ) -> AnyCoordinator<ProfileSwitcherRoute, Void> {
        profileSwitcherCoordinator.asAnyCoordinator()
    }

    func makeSelectLanguageCoordinator(
        stackNavigator: any StackNavigator,
    ) -> AnyCoordinator<SelectLanguageRoute, Void> {
        selectLanguageCoordinatorStackNavigator = stackNavigator
        return selectLanguageCoordinator.asAnyCoordinator()
    }

    func makeSendCoordinator(
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<SendRoute, Void> {
        sendCoordinator.asAnyCoordinator()
    }

    func makeSendItemCoordinator(
        delegate _: SendItemDelegate,
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<SendItemRoute, AuthAction> {
        sendItemCoordinator.asAnyCoordinator()
    }

    func makeSettingsCoordinator(
        delegate _: SettingsCoordinatorDelegate?,
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<SettingsRoute, SettingsEvent> {
        settingsNavigator = stackNavigator
        return settingsCoordinator.asAnyCoordinator()
    }

    func makeTabCoordinator( // swiftlint:disable:this function_parameter_count
        errorReporter _: ErrorReporter,
        rootNavigator _: RootNavigator,
        settingsDelegate _: SettingsCoordinatorDelegate,
        tabNavigator _: TabNavigator,
        vaultDelegate _: VaultCoordinatorDelegate,
        vaultRepository _: VaultRepository,
    ) -> AnyCoordinator<TabRoute, Void> {
        tabCoordinator.asAnyCoordinator()
    }

    func makeVaultCoordinator(
        delegate _: VaultCoordinatorDelegate,
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<VaultRoute, AuthAction> {
        vaultCoordinator.asAnyCoordinator()
    }

    func makeVaultItemCoordinator(
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<VaultItemRoute, VaultItemEvent> {
        vaultItemCoordinator.asAnyCoordinator()
    }
}
