import BitwardenSdk
import Combine

@testable import BitwardenShared

// MARK: - MockSendRepository

class MockSendRepository: SendRepository {
    // MARK: Properties

    var doesActivateAccountHavePremiumResult: Result<Bool, Error> = .success(true)
    var fetchSyncCalled = false
    var fetchSyncIsManualRefresh: Bool?
    var sendListSubject = CurrentValueSubject<[SendListSection], Never>([])

    var addSendResult: Result<Void, Error> = .success(())
    var addSendSendView: SendView?

    // MARK: Methods

    func addSend(_ sendView: SendView) async throws {
        addSendSendView = sendView
        try addSendResult.get()
    }

    func doesActiveAccountHavePremium() async throws -> Bool {
        try doesActivateAccountHavePremiumResult.get()
    }

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
