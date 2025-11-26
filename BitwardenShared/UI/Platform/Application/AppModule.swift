import BitwardenKit
import UIKit

// MARK: AppModule

/// An object that builds coordinators for the app.
@MainActor
public protocol AppModule: AnyObject {
    /// Initializes a coordinator for navigating between `Route`s.
    ///
    /// - Parameters:
    ///   - appContext: The context that the app is running within.
    ///   - navigator: The object that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `AppRoute`s.
    ///
    func makeAppCoordinator(
        appContext: AppContext,
        navigator: RootNavigator,
    ) -> AnyCoordinator<AppRoute, AppEvent>
}

// MARK: - DefaultAppModule

/// The default app module that can be used to build coordinators.
@MainActor
public class DefaultAppModule {
    // MARK: Properties

    /// A delegate used to communicate with the app extension.
    private(set) weak var appExtensionDelegate: AppExtensionDelegate?

    /// The services used by the app.
    let services: Services

    // MARK: Initialization

    /// Creates a new `DefaultAppModule`.
    ///
    /// - Parameters:
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - services: The services used by the app.
    ///
    public init(
        appExtensionDelegate: AppExtensionDelegate? = nil,
        services: ServiceContainer,
    ) {
        self.appExtensionDelegate = appExtensionDelegate
        self.services = services
    }
}

extension DefaultAppModule: AppModule {
    public func makeAppCoordinator(
        appContext: AppContext,
        navigator: RootNavigator,
    ) -> AnyCoordinator<AppRoute, AppEvent> {
        AppCoordinator(
            appContext: appContext,
            appExtensionDelegate: appExtensionDelegate,
            module: self,
            rootNavigator: navigator,
            services: services,
        ).asAnyCoordinator()
    }
}

// MARK: - DefaultAppModule + FlightRecorderModule

extension DefaultAppModule: FlightRecorderModule {
    public func makeFlightRecorderCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<FlightRecorderRoute, Void> {
        FlightRecorderCoordinator(
            services: services,
            stackNavigator: stackNavigator,
        )
        .asAnyCoordinator()
    }
}

// MARK: - DefaultAppModule + NavigatorBuilderModule

extension DefaultAppModule: NavigatorBuilderModule {
    public func makeNavigationController() -> UINavigationController {
        ViewLoggingNavigationController(logger: services.flightRecorder)
    }
}

// MARK: - DefaultAppModule + SelectLanguageModule

extension DefaultAppModule: SelectLanguageModule {
    public func makeSelectLanguageCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<SelectLanguageRoute, Void> {
        SelectLanguageCoordinator(
            services: services,
            stackNavigator: stackNavigator,
        )
        .asAnyCoordinator()
    }
}
