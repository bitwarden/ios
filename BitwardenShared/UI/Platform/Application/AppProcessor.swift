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

        UI.initialLanguageCode = services.appSettingsStore.appLocale
        UI.applyDefaultAppearances()

        Task {
            for await _ in services.notificationCenterService.willEnterForegroundPublisher() {
                let userId = try await self.services.stateService.getActiveAccountId()
                let shouldTimeout = try await services.vaultTimeoutService.shouldSessionTimeout(userId: userId)
                if shouldTimeout {
                    navigatePostTimeout()
                }
            }
        }

        Task {
            for await _ in services.notificationCenterService.didEnterBackgroundPublisher() {
                let userId = try await self.services.stateService.getActiveAccountId()
                try await services.vaultTimeoutService.setLastActiveTime(userId: userId)
            }
        }
    }

    // MARK: Methods

    /// Starts the application flow by navigating the user to the first flow.
    ///
    /// - Parameters:
    ///   - appContext: The context that the app is running within.
    ///   - navigator: The object that will be used to navigate between routes.
    ///   - window: The window to use to set the app's theme.
    ///
    public func start(appContext: AppContext, navigator: RootNavigator, window: UIWindow?) {
        let coordinator = appModule.makeAppCoordinator(appContext: appContext, navigator: navigator)
        coordinator.start()
        self.coordinator = coordinator

        Task {
            for await appTheme in await services.stateService.appThemePublisher().values {
                navigator.appTheme = appTheme
                window?.overrideUserInterfaceStyle = appTheme.userInterfaceStyle
            }
        }
        Task {
            await services.environmentService.loadURLsForActiveAccount()
        }

        if let activeAccount = services.appSettingsStore.state?.activeAccount {
            let vaultTimeout = services.appSettingsStore.vaultTimeout(userId: activeAccount.profile.userId)
            if vaultTimeout == -1 {
                navigatePostTimeout()
            } else {
                coordinator.navigate(to: .auth(.vaultUnlock(activeAccount)))
            }
        } else {
            coordinator.navigate(to: .auth(.landing))
        }
    }

    // MARK: Private methods

    /// Navigates when a session timeout occurs.
    ///
    private func navigatePostTimeout() {
        guard let account = services.appSettingsStore.state?.activeAccount else { return }
        guard let action = services.appSettingsStore.timeoutAction(userId: account.profile.userId) else { return }
        switch action {
        case 0:
            coordinator?.navigate(to: .auth(.vaultUnlock(account)))
        case 1:
            Task {
                try await services.stateService.logoutAccount(userId: account.profile.userId)
            }
            coordinator?.navigate(to: .auth(.landing))
        default:
            break
        }
    }
}
