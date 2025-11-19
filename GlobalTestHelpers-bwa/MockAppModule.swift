@testable import AuthenticatorShared
import BitwardenKit
import BitwardenKitMocks
import UIKit

// MARK: - MockAppModule

class MockAppModule:
    AppModule,
    AuthModule,
    DebugMenuModule,
    FileSelectionModule,
    FlightRecorderModule,
    ItemListModule,
    NavigatorBuilderModule,
    TutorialModule,
    TabModule {
    var appCoordinator = MockCoordinator<AppRoute, AppEvent>()
    var authCoordinator = MockCoordinator<AuthRoute, AuthEvent>()
    var authRouter = MockRouter<AuthEvent, AuthRoute>(routeForEvent: { _ in .vaultUnlock })
    var debugMenuCoordinator = MockCoordinator<DebugMenuRoute, Void>()
    var fileSelectionDelegate: FileSelectionDelegate?
    var fileSelectionCoordinator = MockCoordinator<FileSelectionRoute, FileSelectionEvent>()
    var flightRecorderCoordinator = MockCoordinator<FlightRecorderRoute, Void>()
    var itemListCoordinator = MockCoordinator<ItemListRoute, ItemListEvent>()
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
        stackNavigator _: StackNavigator,
    ) -> AnyCoordinator<ItemListRoute, ItemListEvent> {
        itemListCoordinator.asAnyCoordinator()
    }

    func makeNavigationController() -> UINavigationController {
        UINavigationController()
    }

    func makeTabCoordinator(
        errorReporter _: ErrorReporter,
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
