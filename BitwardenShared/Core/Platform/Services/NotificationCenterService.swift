import Combine
import UIKit

protocol NotificationCenterService: AnyObject {
    func didEnterBackgroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>>

    func willEnterForegroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>>
}

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
