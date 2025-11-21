import TestHarnessShared
import UIKit

/// The app's `UIApplicationDelegate` used when running tests.
class TestingAppDelegate: UIResponder, UIApplicationDelegate, AppDelegateType {
    // MARK: Properties

    /// The processor that manages application level logic.
    var appProcessor: AppProcessor?

    /// Whether the app is running for unit tests.
    var isTesting: Bool {
        true
    }

    // MARK: Methods

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil,
    ) -> Bool {
        true
    }
}
