import Combine
import UIKit

// MARK: - NotificationCenterService

/// A protocol for a `NotificationCenterService` which accesses the app's notification center.
///
protocol NotificationCenterService: AnyObject {
    /// A publisher for when the app enters the background.
    ///
    func didEnterBackgroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>>

    /// A publisher for when the app enters the foreground.
    ///
    func willEnterForegroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>>
}

// MARK: - DefaultNotificationCenterService

/// A default implementation of the `NotificationCenterService` which accesses the app's notification center.
///
class DefaultNotificationCenterService: NotificationCenterService {
    // MARK: Properties

    /// The NotificationCenter to use in subscribing to notifications.
    let notificationCenter: NotificationCenter

    // MARK: Initialization

    /// Initialize a `DefaultNotificationCenterService`.
    ///
    /// - Parameter notificationCenter: The NotificationCenter to use in subscribing to notifications.
    ///
    init(notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.notificationCenter = notificationCenter
    }

    // MARK: Methods

    func didEnterBackgroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>> {
        notificationCenter
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .map { _ in }
            .eraseToAnyPublisher()
            .values
    }

    func willEnterForegroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>> {
        notificationCenter
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .map { _ in }
            .eraseToAnyPublisher()
            .values
    }
}
