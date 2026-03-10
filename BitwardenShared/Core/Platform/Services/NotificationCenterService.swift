import Combine
import UIKit

// MARK: - NotificationCenterService

/// A protocol for a `NotificationCenterService` which accesses the app's notification center.
///
protocol NotificationCenterService: AnyObject {
    /// A publisher for when the app enters the background.
    ///
    func didEnterBackgroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>>

    /// A publisher that emits the app's current foreground state, starting with `false`.
    /// In app extension contexts, `willEnterForegroundNotification` is never posted (the host
    /// app is already in the foreground when an extension activates), so this publisher will
    /// always emit `false` in extensions. Consumers that require foreground gating should
    /// only subscribe in main app contexts.
    ///
    func isInForegroundPublisher() -> AsyncPublisher<AnyPublisher<Bool, Never>>

    /// A publisher for when the app enters the foreground.
    ///
    func willEnterForegroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>>
}

// MARK: - DefaultNotificationCenterService

/// A default implementation of the `NotificationCenterService` which accesses the app's notification center.
///
class DefaultNotificationCenterService: NotificationCenterService {
    // MARK: Properties

    /// Cancellables for any subscriptions owned by the service.
    private var cancellables = Set<AnyCancellable>()

    /// The subject tracking the app's current foreground state.
    private let isInForegroundSubject = CurrentValueSubject<Bool, Never>(false)

    /// The NotificationCenter to use in subscribing to notifications.
    private let notificationCenter: NotificationCenter

    // MARK: Initialization

    /// Initialize a `DefaultNotificationCenterService`.
    ///
    /// - Parameter notificationCenter: The NotificationCenter to use in subscribing to notifications.
    ///
    init(notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.notificationCenter = notificationCenter

        notificationCenter
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in self?.isInForegroundSubject.send(false) }
            .store(in: &cancellables)

        notificationCenter
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in self?.isInForegroundSubject.send(true) }
            .store(in: &cancellables)
    }

    // MARK: Methods

    func didEnterBackgroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>> {
        notificationCenter
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .map { _ in }
            .eraseToAnyPublisher()
            .values
    }

    func isInForegroundPublisher() -> AsyncPublisher<AnyPublisher<Bool, Never>> {
        isInForegroundSubject.eraseToAnyPublisher().values
    }

    func willEnterForegroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>> {
        notificationCenter
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .map { _ in }
            .eraseToAnyPublisher()
            .values
    }
}
