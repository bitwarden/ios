// MARK: AppModule

/// An object that builds coordinators for the app.
@MainActor
public protocol AppModule: AnyObject {
    /// Initializes a coordinator for navigating between `Route`s.
    ///
    /// - Parameter navigator: The object that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `AppRoute`s.
    ///
    func makeAppCoordinator(navigator: RootNavigator) -> AnyCoordinator<AppRoute>
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
    /// - Parameter services: The services used by the app.
    ///
    public init(services: ServiceContainer) {
        self.services = services
    }
}

extension DefaultAppModule: AppModule {
    public func makeAppCoordinator(navigator: RootNavigator) -> AnyCoordinator<AppRoute> {
        AppCoordinator(
            module: self,
            navigator: navigator
        ).asAnyCoordinator()
    }
}
