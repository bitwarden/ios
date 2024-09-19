import Combine
import Foundation

@testable import BitwardenShared

class MockNotificationCenterService: NotificationCenterService {
    var didEnterBackgroundSubject = CurrentValueSubject<Void, Never>(())
    var didEnterBackgroundSubscribers = 0
    var willEnterForegroundSubject = CurrentValueSubject<Void, Never>(())
    var willEnterForegroundSubscribers = 0

    func didEnterBackgroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>> {
        didEnterBackgroundSubscribers += 1
        return didEnterBackgroundSubject.eraseToAnyPublisher().values
    }

    func willEnterForegroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>> {
        willEnterForegroundSubscribers += 1
        return willEnterForegroundSubject.eraseToAnyPublisher().values
    }
}
