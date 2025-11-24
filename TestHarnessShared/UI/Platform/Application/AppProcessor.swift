import BitwardenKit
import Combine
import Foundation
import UIKit

/// The `AppProcessor` processes actions received at the application level and contains the logic
/// to control the top-level flow through the app.
///
@MainActor
public class AppProcessor {
    // MARK: Properties

    /// The root module to use to create sub-coordinators.
    let appModule: AppModule

    /// The root coordinator of the app.
    var coordinator: AnyCoordinator<AppRoute, AppEvent>?

    /// The services used by the app.
    let services: ServiceContainer

    // MARK: Initialization

    /// Initializes an `AppProcessor`.
    ///
    /// - Parameters:
    ///   - appModule: The root module to use to create sub-coordinators.
    ///   - services: The services used by the app.
    ///
    public init(
        appModule: AppModule,
        services: ServiceContainer,
    ) {
        self.appModule = appModule
        self.services = services

        UI.applyDefaultAppearances()
    }

    // MARK: Methods

    /// Starts the application flow by navigating the user to the first flow.
    ///
    /// - Parameters:
    ///   - navigator: The object that will be used to navigate between routes.
    ///   - window: The window to use to set the app's theme.
    ///
    public func start(
        navigator: RootNavigator,
        window: UIWindow?,
    ) async {
        let coordinator = appModule.makeAppCoordinator(navigator: navigator)
        coordinator.start()
        self.coordinator = coordinator

        await coordinator.handleEvent(.didStart)
    }
}
