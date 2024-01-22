import BitwardenSdk
import Combine

@testable import BitwardenShared

// MARK: - MockSendRepository

class MockSendRepository: SendRepository {
    // MARK: Properties

    var doesActivateAccountHavePremiumResult: Result<Bool, Error> = .success(true)

    var fetchSyncCalled = false
    var fetchSyncIsManualRefresh: Bool?
    var fetchSyncResult: Result<Void, Error> = .success(())

    var searchSendSubject = CurrentValueSubject<[SendListItem], Error>([])

    var sendListSubject = CurrentValueSubject<[SendListSection], Error>([])

    var addSendResult: Result<Void, Error> = .success(())
    var addSendSendView: SendView?

    var updateSendResult: Result<Void, Error> = .success(())
    var updateSendSendView: SendView?

    // MARK: Methods

    func addSend(_ sendView: SendView) async throws {
        addSendSendView = sendView
        try addSendResult.get()
    }

    func updateSend(_ sendView: SendView) async throws {
        updateSendSendView = sendView
        try updateSendResult.get()
    }

    func doesActiveAccountHavePremium() async throws -> Bool {
        try doesActivateAccountHavePremiumResult.get()
    }

    func fetchSync(isManualRefresh: Bool) async throws {
        fetchSyncCalled = true
        fetchSyncIsManualRefresh = isManualRefresh
        try fetchSyncResult.get()
    }

    func searchSendPublisher(
        searchText: String
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[SendListItem], Error>> {
        searchSendSubject.eraseToAnyPublisher().values
    }

    func sendListPublisher() -> AsyncThrowingPublisher<AnyPublisher<[SendListSection], Error>> {
        sendListSubject
            .eraseToAnyPublisher()
            .values
    }
}
