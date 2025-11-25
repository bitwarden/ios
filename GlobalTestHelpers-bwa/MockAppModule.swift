@testable import AuthenticatorShared
import BitwardenKit
import BitwardenKitMocks
import UIKit

// MARK: - MockAppModule

class MockAppModule:
    AppModule,
    AuthModule,
    AuthenticatorItemModule,
    DebugMenuModule,
    FileSelectionModule,
    FlightRecorderModule,
    ItemListModule,
    NavigatorBuilderModule,
    SelectLanguageModule,
    SettingsModule,
    TabModule,
    TutorialModule {
    var appCoordinator = MockCoordinator<AppRoute, AppEvent>()
    var authCoordinator = MockCoordinator<AuthRoute, AuthEvent>()
    var authRouter = MockRouter<AuthEvent, AuthRoute>(routeForEvent: { _ in .vaultUnlock })
    var authenticatorItemCoordinator = MockCoordinator<AuthenticatorItemRoute, AuthenticatorItemEvent>()
    var debugMenuCoordinator = MockCoordinator<DebugMenuRoute, Void>()
    var fileSelectionDelegate: FileSelectionDelegate?
    var fileSelectionCoordinator = MockCoordinator<FileSelectionRoute, FileSelectionEvent>()
    var flightRecorderCoordinator = MockCoordinator<FlightRecorderRoute, Void>()
    var itemListCoordinator = MockCoordinator<ItemListRoute, ItemListEvent>()
    var itemListCoordinatorDelegate: ItemListCoordinatorDelegate?
    var selectLanguageCoordinator = MockCoordinator<SelectLanguageRoute, Void>()
    // swiftlint:disable:next weak_navigator identifier_name
    var selectLanguageCoordinatorStackNavigator: StackNavigator?
    var settingsCoordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
    var tabCoordinator = MockCoordinator<TabRoute, Void>()
    var tutorialCoordinator = MockCoordinator<TutorialRoute, TutorialEvent>()

    func makeAppCoordinator(
        appContext _: AppContext,
        navigator _: RootNavigator,
    ) -> AnyCoordinator<AppRoute, AppEvent> {
        appCoordinator.asAnyCoordinator()
    }

    func makeAuthCoordinator(
        delegate _: AuthCoordinatorDelegate,
        rootNavigator _: RootNavigator,
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<AuthRoute, AuthEvent> {
        authCoordinator.asAnyCoordinator()
    }

    func makeAuthRouter() -> AnyRouter<AuthEvent, AuthRoute> {
        authRouter.asAnyRouter()
    }

    func makeAuthenticatorItemCoordinator(
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<AuthenticatorItemRoute, AuthenticatorItemEvent> {
        authenticatorItemCoordinator.asAnyCoordinator()
    }

    func makeDebugMenuCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<DebugMenuRoute, Void> {
        debugMenuCoordinator.asAnyCoordinator()
    }

    func makeFileSelectionCoordinator(
        delegate: FileSelectionDelegate,
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<FileSelectionRoute, FileSelectionEvent> {
        fileSelectionDelegate = delegate
        return fileSelectionCoordinator.asAnyCoordinator()
    }

    func makeFlightRecorderCoordinator(
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<FlightRecorderRoute, Void> {
        flightRecorderCoordinator.asAnyCoordinator()
    }

    func makeItemListCoordinator(
        delegate: ItemListCoordinatorDelegate,
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<ItemListRoute, ItemListEvent> {
        itemListCoordinatorDelegate = delegate
        return itemListCoordinator.asAnyCoordinator()
    }

    func makeSettingsCoordinator(
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<SettingsRoute, SettingsEvent> {
        settingsCoordinator.asAnyCoordinator()
    }

    func makeNavigationController() -> UINavigationController {
        UINavigationController()
    }

    func makeSelectLanguageCoordinator(
        stackNavigator: any StackNavigator,
    ) -> AnyCoordinator<SelectLanguageRoute, Void> {
        selectLanguageCoordinatorStackNavigator = stackNavigator
        return selectLanguageCoordinator.asAnyCoordinator()
    }

    func makeTabCoordinator(
        errorReporter _: ErrorReporter,
        itemListDelegate _: ItemListCoordinatorDelegate,
        rootNavigator _: RootNavigator,
        tabNavigator _: TabNavigator,
    ) -> AnyCoordinator<TabRoute, Void> {
        tabCoordinator.asAnyCoordinator()
    }

    func makeTutorialCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<TutorialRoute, TutorialEvent> {
        tutorialCoordinator.asAnyCoordinator()
    }
}
