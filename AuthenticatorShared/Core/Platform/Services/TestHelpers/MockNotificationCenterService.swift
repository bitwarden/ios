import Combine
import Foundation

@testable import AuthenticatorShared

class MockNotificationCenterService: NotificationCenterService {
    var didEnterBackgroundSubject = PassthroughSubject<Void, Never>()
    var willEnterForegroundSubject = PassthroughSubject<Void, Never>()

    func didEnterBackgroundPublisher() -> AnyPublisher<Void, Never> {
        didEnterBackgroundSubject.eraseToAnyPublisher()
    }

    func willEnterForegroundPublisher() -> AnyPublisher<Void, Never> {
        willEnterForegroundSubject.eraseToAnyPublisher()
    }
}
