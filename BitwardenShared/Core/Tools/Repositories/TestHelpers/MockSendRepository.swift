import Combine

@testable import BitwardenShared

// MARK: - MockSendRepository

class MockSendRepository: SendRepository {
    // MARK: Properties

    var fetchSyncCalled = false
    var fetchSyncIsManualRefresh: Bool?
    var sendListSubject = CurrentValueSubject<[SendListSection], Never>([])

    // MARK: Methods

    func fetchSync(isManualRefresh: Bool) async throws {
        fetchSyncCalled = true
        fetchSyncIsManualRefresh = isManualRefresh
    }

    func sendListPublisher() -> AsyncPublisher<AnyPublisher<[SendListSection], Never>> {
        sendListSubject
            .eraseToAnyPublisher()
            .values
    }
}
