import UIKit

/// A protocol for the application instance (i.e. `UIApplication`).
///
public protocol Application {
    /// Marks the start of a task with a custom name that should continue if the app enters the background.
    ///
    nonisolated
    func beginBackgroundTask(
        withName: String?,
        expirationHandler: (() -> Void)?
    ) -> UIBackgroundTaskIdentifier

    /// Marks the end of a specific long-running background task.
    ///
    nonisolated
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)

    /// Registers the application to receive remote push notifications.
    ///
    func registerForRemoteNotifications()
}
