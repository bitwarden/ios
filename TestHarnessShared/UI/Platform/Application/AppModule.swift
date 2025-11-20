import BitwardenKit
import Foundation

// MARK: - AppModule

/// A protocol for an object that contains the dependencies for creating coordinators in the app flow.
///
@MainActor
public protocol AppModule: AnyObject {
    /// Creates an `AppCoordinator`.
    ///
    /// - Parameter navigator: The navigator to use for presenting screens.
    /// - Returns: An `AppCoordinator` instance.
    ///
    func makeAppCoordinator(
        navigator: RootNavigator,
    ) -> AnyCoordinator<AppRoute, AppEvent>
}

// MARK: - DefaultAppModule

/// A default implementation of `AppModule`.
///
@MainActor
public class DefaultAppModule: AppModule {
    // MARK: Properties

    /// The services used by the module.
    let services: ServiceContainer

    // MARK: Initialization

    /// Initialize a `DefaultAppModule`.
    ///
    /// - Parameter services: The services used by the module.
    ///
    public init(services: ServiceContainer) {
        self.services = services
    }

    // MARK: Methods

    public func makeAppCoordinator(
        navigator: RootNavigator,
    ) -> AnyCoordinator<AppRoute, AppEvent> {
        AppCoordinator(
            module: self,
            rootNavigator: navigator,
            services: services,
        ).asAnyCoordinator()
    }
}

// MARK: - RootModule

extension DefaultAppModule: RootModule {
    func makeRootCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<RootRoute, Void> {
        RootCoordinator(
            services: services,
            stackNavigator: stackNavigator,
        ).asAnyCoordinator()
    }
}
