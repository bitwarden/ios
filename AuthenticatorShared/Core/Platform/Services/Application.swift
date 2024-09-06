import Foundation

/// A protocol for the application instance (i.e. `UIApplication`).
///
public protocol Application {
    /// Registers the application to receive remote push notifications.
    ///
    func registerForRemoteNotifications()

    /// Checks if the given url can be opened on this device.
    ///
    /// - Parameter url: The url to check.
    ///
    func canOpenURL(_ url: URL) -> Bool
}
