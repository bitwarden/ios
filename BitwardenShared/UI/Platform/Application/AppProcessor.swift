import Foundation

/// The `AppProcessor` processes actions received at the application level and contains the logic
/// to control the top-level flow through the app.
///
@MainActor
public class AppProcessor {
    // MARK: Properties

    /// The root module to use to create sub-coordinators.
    let appModule: AppModule

    /// The root coordinator of the app.
    var coordinator: AnyCoordinator<AppRoute>?

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
        services: ServiceContainer
    ) {
        self.appModule = appModule
        self.services = services

        UI.applyDefaultAppearances()
    }

    // MARK: Methods

    /// Starts the application flow by navigating the user to the first flow.
    ///
    /// - Parameter navigator: The object that will be used to navigate between routes.
    ///
    public func start(navigator: RootNavigator) {
        let coordinator = appModule.makeAppCoordinator(navigator: navigator)
        coordinator.start()
        self.coordinator = coordinator

        if let activeAccount = services.appSettingsStore.state?.activeAccount {
            coordinator.navigate(to: .auth(.vaultUnlock(activeAccount)))
        } else {
            coordinator.navigate(to: .auth(.landing))
        }
    }
}
