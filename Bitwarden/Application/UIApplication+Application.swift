import BitwardenShared
import UIKit

extension UIApplication: Application {
    public func startBackgroundTask(withName: String?, expirationHandler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        // Because the annotations for `UIApplication.beginBackgroundTask(::)` changed
        // between Xcode 15.4 and Xcode 16 and also between Swift 5 and Swift 6,
        // we need this shim to make the same thing compile across the board.
        // Once we migrate to Swift 6 + Xcode 16, we can return to a more transparent
        // protocol method
        // TODO: PM-11189
        beginBackgroundTask(withName: withName, expirationHandler: expirationHandler)
    }
}
