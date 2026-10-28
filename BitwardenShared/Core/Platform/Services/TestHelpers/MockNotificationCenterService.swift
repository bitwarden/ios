import Combine
import Foundation

@testable import BitwardenShared

class MockNotificationCenterService: NotificationCenterService {
    var didEnterBackgroundSubject = CurrentValueSubject<Void, Never>(())
    var isInForegroundSubject = CurrentValueSubject<Bool, Never>(true)
    var willResignActiveSubject = PassthroughSubject<Void, Never>()
    /// Whether a subscriber has requested values from `willResignActivePublisher()`, so tests can
    /// wait for the listener before sending to the passthrough subject.
    var willResignActiveSubscribed = false
    var willEnterForegroundSubject = CurrentValueSubject<Void, Never>(())

    func didEnterBackgroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>> {
        didEnterBackgroundSubject.eraseToAnyPublisher().values
    }

    func isInForegroundPublisher() -> AsyncPublisher<AnyPublisher<Bool, Never>> {
        isInForegroundSubject.eraseToAnyPublisher().values
    }

    func willResignActivePublisher() -> AsyncPublisher<AnyPublisher<Void, Never>> {
        willResignActiveSubject
            .handleEvents(receiveRequest: { [weak self] _ in self?.willResignActiveSubscribed = true })
            .eraseToAnyPublisher()
            .values
    }

    func willEnterForegroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>> {
        willEnterForegroundSubject.eraseToAnyPublisher().values
    }
}
