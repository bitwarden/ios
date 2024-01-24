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
    ///   - initialRoute: The initial route to navigate to. If `nil` this, will navigate to the
    ///     unlock or landing auth route based on if there's an active account. Defaults to `nil`.
    ///   - navigator: The object that will be used to navigate between routes.
    ///   - window: The window to use to set the app's theme.
    ///
    public func start(
        appContext: AppContext,
        initialRoute: AppRoute? = nil,
        navigator: RootNavigator,
        window: UIWindow?
    ) {
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

        if let initialRoute {
            coordinator.navigate(to: initialRoute)
        } else if let activeAccount = services.appSettingsStore.state?.activeAccount {
            let vaultTimeout = services.appSettingsStore.vaultTimeout(userId: activeAccount.profile.userId)
            if vaultTimeout == SessionTimeoutValue.onAppRestart.rawValue {
                navigatePostTimeout()
            } else {
                coordinator.navigate(
                    to: .auth(
                        .vaultUnlock(
                            activeAccount,
                            attemptAutomaticBiometricUnlock: true,
                            didSwitchAccountAutomatically: false
                        )
                    )
                )
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
        case SessionTimeoutAction.lock.rawValue:
            coordinator?.navigate(to: .auth(.vaultUnlock(account, didSwitchAccountAutomatically: false)))
        case SessionTimeoutAction.logout.rawValue:
            Task {
                try await services.stateService.logoutAccount(userId: account.profile.userId)
            }
            coordinator?.navigate(to: .auth(.landing))
        default:
            break
        }
    }

    // MARK: Notification Methods

    /// Called when the app has registered for push notifications.
    ///
    /// - Parameter tokenData: The device token for push notifications.
    ///
    public func didRegister(withToken tokenData: Data) {
        Task {
            await services.notificationService.didRegister(withToken: tokenData)
        }
    }

    /// Called when the app failed to register for push notifications.
    ///
    /// - Parameter error: The error received.
    ///
    public func failedToRegister(_ error: Error) {
        services.errorReporter.log(error: error)
    }

    /// Called when the app has received data from a push notification.
    ///
    /// - Parameters:
    ///   - message: The content of the push notification.
    ///   - notificationDismissed: `true` if a notification banner has been dismissed.
    ///   - notificationTapped: `true` if a notification banner has been tapped.
    ///
    public func messageReceived(
        _ message: [AnyHashable: Any],
        notificationDismissed: Bool? = nil,
        notificationTapped: Bool? = nil
    ) async {
        await services.notificationService.messageReceived(
            message,
            notificationDismissed: notificationDismissed,
            notificationTapped: notificationTapped
        )
    }
}
