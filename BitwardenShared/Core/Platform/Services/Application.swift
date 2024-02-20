/// A protocol for the application instance (i.e. `UIApplication`).
///
public protocol Application {
    /// Registers the application to receive remote push notifications.
    ///
    func registerForRemoteNotifications()
}
