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
    /// - Parameters:
    ///   - appContext: The context that the app is running within.
    ///   - navigator: The object that will be used to navigate between routes.
    ///
    public func start(appContext: AppContext, navigator: RootNavigator) {
        let coordinator = appModule.makeAppCoordinator(appContext: appContext, navigator: navigator)
        coordinator.start()
        self.coordinator = coordinator

        Task {
            await services.environmentService.loadURLsForActiveAccount()
        }

        Task {
            for await shouldClearData in services.vaultTimeoutService.shouldClearDecryptedDataPublisher() {
                guard shouldClearData else { continue }
                services.syncService.clearCachedData()
            }
        }

        if let activeAccount = services.appSettingsStore.state?.activeAccount {
            if let loginWithPIN = services.appSettingsStore.pinKeyEncryptedUserKey(
                userId: activeAccount.profile.userId
            ) {
                coordinator.navigate(to: .auth(.loginWithPIN))
            } else {
                coordinator.navigate(to: .auth(.vaultUnlock(activeAccount)))
            }
        } else {
            coordinator.navigate(to: .auth(.landing))
        }
    }
}
