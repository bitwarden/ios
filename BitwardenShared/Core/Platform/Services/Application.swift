import UIKit

/// A protocol for the application instance (i.e. `UIApplication`).
///
public protocol Application {
    /// The current state of the application (i.e. foreground, inactive, background)
    @MainActor var applicationState: UIApplication.State { get }

    /// Marks the start of a task with a custom name that should continue if the app enters the background.
    /// See note in `UIApplication+Application.swift`
    /// TODO: PM-11189
    ///
    nonisolated
    func startBackgroundTask(
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
