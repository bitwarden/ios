import Combine

@testable import BitwardenShared

// MARK: - MockSendRepository

class MockSendRepository: SendRepository {
    // MARK: Properties

    var fetchSyncCalled = false
    var sendListSubject = CurrentValueSubject<[SendListSection], Never>([])

    // MARK: Methods

    func fetchSync() async throws {
        fetchSyncCalled = true
    }

    func sendListPublisher() -> AsyncPublisher<AnyPublisher<[SendListSection], Never>> {
        sendListSubject
            .eraseToAnyPublisher()
            .values
    }
}
