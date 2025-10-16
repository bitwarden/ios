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

    /// The number of notifications configured being listened to on publishers.
    /// This is useful in tests to avoid race-conditions where the tasks to subscribe to the publishers
    /// start late and the notification sent gets missed from there.
    var notificationsListeningCount: Int = 0

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

        UI.initialLanguageCode = services.appSettingsStore.appLocale ?? Locale.current.languageCode
        UI.applyDefaultAppearances()

        Task {
            notificationsListeningCount += 1
            for await _ in services.notificationCenterService.willEnterForegroundPublisher().values {
                let userId = await services.stateService.getActiveAccountId()

                if vaultHasTimedOut(userId: userId) {
                    await coordinator?.handleEvent(.vaultTimeout)
                }
            }
        }

        Task {
            notificationsListeningCount += 1
            for await _ in services.notificationCenterService.didEnterBackgroundPublisher().values {
                let userId = await services.stateService.getActiveAccountId()
                services.appSettingsStore.setLastActiveTime(.now, userId: userId)
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
        window: UIWindow?,
    ) async {
        let coordinator = appModule.makeAppCoordinator(appContext: appContext, navigator: navigator)
        coordinator.start()
        self.coordinator = coordinator

        Task {
            for await appTheme in await services.stateService.appThemePublisher().values {
                navigator.appTheme = appTheme
                window?.overrideUserInterfaceStyle = appTheme.userInterfaceStyle
            }
        }

        await services.migrationService.performMigrations()

        _ = await services.configService.getConfig()

        if let initialRoute {
            coordinator.navigate(to: initialRoute)
        } else {
            await coordinator.handleEvent(.didStart)
        }
    }

    #if DEBUG_MENU
    /// Show the debug menu.
    public func showDebugMenu() {
        coordinator?.navigate(to: .debugMenu)
    }
    #endif

    /// Calculate if the user has passed the timeout set for their vault session.
    ///
    /// - Parameter userId: The active user.
    /// - Returns: `true` if the user has timed out and needs to re-authenticate,
    ///     `false` if they are within their timeout session and can continue without re-authenticating.
    ///
    private func vaultHasTimedOut(userId: String) -> Bool {
        guard let rawValue = services.appSettingsStore.vaultTimeout(userId: userId) else {
            return false
        }
        let vaultTimeout = SessionTimeoutValue(rawValue: rawValue)

        switch vaultTimeout {
        case .never,
             .onAppRestart:
            // For timeouts of `.never` or `.onAppRestart`, timeouts cannot be calculated.
            // In these cases, return false.
            return false
        default:
            // Otherwise, calculate a timeout.
            guard let lastActiveTime = services.appSettingsStore.lastActiveTime(userId: userId) else {
                return true
            }

            return services.timeProvider.presentTime.timeIntervalSince(lastActiveTime)
                >= TimeInterval(vaultTimeout.seconds)
        }
    }
}
