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
    func didEnterBackgroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>> {
        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .map { _ in }
            .eraseToAnyPublisher()
            .values
    }

    func willEnterForegroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>> {
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .map { _ in }
            .eraseToAnyPublisher()
            .values
    }
}
