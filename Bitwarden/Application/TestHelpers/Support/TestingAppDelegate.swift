import BitwardenShared
import UIKit

@testable import Bitwarden

/// A replacement for `AppDelegate` that allows for checking that certain app delegate methods get called at the
/// appropriate times during unit tests.
///
class TestingAppDelegate: NSObject, UIApplicationDelegate, AppDelegateType {
    var appProcessor: AppProcessor?
    var isTesting = false
}
