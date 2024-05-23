import BitwardenShared
import UIKit

/// A protocol for an `AppDelegate` that can be used by the `SceneDelegate` to look up the
/// `AppDelegate` when the app is running (`AppDelegate`) or testing (`TestingAppDelegate`).
///
protocol AppDelegateType: AnyObject {
    /// The processor that manages application level logic.
    var appProcessor: AppProcessor? { get }

    /// Whether the app is running for unit tests.
    var isTesting: Bool { get }
}

/// The app's `UIApplicationDelegate` which serves as the entry point into the app.
///
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, AppDelegateType {
    // MARK: Properties

    /// The processor that manages application level logic.
    var appProcessor: AppProcessor?

    /// Whether the app is running for unit tests.
    var isTesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-testing")
    }

    // MARK: Methods

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Exit early if testing to avoid running any app functionality.
        guard !isTesting else { return true }

        UNUserNotificationCenter.current().delegate = self

        #if DEBUG
        let errorReporter = OSLogErrorReporter()
        #else
        let errorReporter = CrashlyticsErrorReporter()
        #endif

        let services = ServiceContainer(
            application: UIApplication.shared,
            errorReporter: errorReporter,
            nfcReaderService: DefaultNFCReaderService()
        )
        let appModule = DefaultAppModule(services: services)
        appProcessor = AppProcessor(appModule: appModule, services: services)
        return true
    }

    /// Successfully registered for push notifications.
    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        appProcessor?.didRegister(withToken: deviceToken)
    }

    /// Record an error if registering for push notifications failed.
    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        appProcessor?.failedToRegister(error)
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        await appProcessor?.messageReceived(userInfo)
        return .newData
    }

    /// Handle universal links.
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Get URL components from the incoming user activity.
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL,
              let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
            return false
        }

        // Check for specific URL components that you need.
        guard let path = components.path,
              let params = components.queryItems else {
            return false
        }
        print("path = \(path)")

        if let albumName = params.first(where: { $0.name == "albumname" })?.value,
           let photoIndex = params.first(where: { $0.name == "index" })?.value {
            print("album = \(albumName)")
            print("photoIndex = \(photoIndex)")
            return true

        } else {
            print("Either album name or photo index missing")
            return false
        }
    }

    /// Received a response to a push notification alert.
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await appProcessor?.messageReceived(
            response.notification.request.content.userInfo,
            notificationDismissed: response.actionIdentifier == UNNotificationDismissActionIdentifier,
            notificationTapped: response.actionIdentifier == UNNotificationDefaultActionIdentifier
        )
    }

    /// Received a message in the foreground of the app.
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        await appProcessor?.messageReceived(notification.request.content.userInfo)
        return .banner
    }
}
