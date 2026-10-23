import Combine
import Foundation

@testable import BitwardenShared

class MockNotificationCenterService: NotificationCenterService {
    var didEnterBackgroundSubject = CurrentValueSubject<Void, Never>(())
    var isInForegroundSubject = CurrentValueSubject<Bool, Never>(true)
    var willResignActiveSubject = PassthroughSubject<Void, Never>()
    var willEnterForegroundSubject = CurrentValueSubject<Void, Never>(())

    func didEnterBackgroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>> {
        didEnterBackgroundSubject.eraseToAnyPublisher().values
    }

    func isInForegroundPublisher() -> AsyncPublisher<AnyPublisher<Bool, Never>> {
        isInForegroundSubject.eraseToAnyPublisher().values
    }

    func willResignActivePublisher() -> AsyncPublisher<AnyPublisher<Void, Never>> {
        willResignActiveSubject.eraseToAnyPublisher().values
    }

    func willEnterForegroundPublisher() -> AsyncPublisher<AnyPublisher<Void, Never>> {
        willEnterForegroundSubject.eraseToAnyPublisher().values
    }
}
