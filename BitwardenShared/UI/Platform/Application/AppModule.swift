// MARK: AppModule

/// An object that builds coordinators for the app.
@MainActor
public protocol AppModule: AnyObject {
    /// Initializes a coordinator for navigating between `Route`s.
    ///
    /// - Parameter navigator: The object that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `Route`s.
    ///
    func makeAppCoordinator(navigator: RootNavigator) -> AnyCoordinator<AppRoute>
}

// MARK: - DefaultAppModule

/// The default app module that can be used to build coordinators.
@MainActor
public class DefaultAppModule {
    /// Creates a new `DefaultAppModule`.
    public init() {}
}

extension DefaultAppModule: AppModule {
    public func makeAppCoordinator(navigator: RootNavigator) -> AnyCoordinator<AppRoute> {
        AppCoordinator(
            module: self,
            navigator: navigator
        ).asAnyCoordinator()
    }
}
