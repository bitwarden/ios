import AuthenticatorShared
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
            errorReporter: errorReporter
        )
        let appModule = DefaultAppModule(services: services)
        appProcessor = AppProcessor(appModule: appModule, services: services)
        return true
    }
}
