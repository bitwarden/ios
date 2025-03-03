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
        navigator: RootNavigator
    ) -> AnyCoordinator<AppRoute, AppEvent>
}

// MARK: - DefaultAppModule

/// The default app module that can be used to build coordinators.
@MainActor
public class DefaultAppModule {
    // MARK: Properties

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
        services: ServiceContainer
    ) {
        self.services = services
    }
}

extension DefaultAppModule: AppModule {
    public func makeAppCoordinator(
        appContext: AppContext,
        navigator: RootNavigator
    ) -> AnyCoordinator<AppRoute, AppEvent> {
        AppCoordinator(
            appContext: appContext,
            module: self,
            rootNavigator: navigator,
            services: services
        ).asAnyCoordinator()
    }
}
