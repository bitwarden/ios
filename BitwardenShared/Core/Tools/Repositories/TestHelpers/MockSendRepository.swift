import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

// MARK: - MockSendRepository

class MockSendRepository: SendRepository {
    // MARK: Properties

    var doesActivateAccountHavePremiumResult: Result<Bool, Error> = .success(true)

    var fetchSyncCalled = false
    var fetchSyncIsManualRefresh: Bool?
    var fetchSyncResult: Result<Void, Error> = .success(())

    var sendListSubject = CurrentValueSubject<[SendListSection], Error>([])

    var addFileSendResult: Result<Void, Error> = .success(())
    var addFileSendData: Data?
    var addFileSendSendView: SendView?

    var addTextSendResult: Result<Void, Error> = .success(())
    var addTextSendSendView: SendView?

    var deleteSendResult: Result<Void, Error> = .success(())
    var deleteSendSendView: SendView?

    var updateSendResult: Result<Void, Error> = .success(())
    var updateSendSendView: SendView?

    // MARK: Methods

    func addFileSend(_ sendView: SendView, data: Data) async throws {
        addFileSendSendView = sendView
        addFileSendData = data
        try addFileSendResult.get()
    }

    func addTextSend(_ sendView: SendView) async throws {
        addTextSendSendView = sendView
        try addTextSendResult.get()
    }

    func deleteSend(_ sendView: SendView) async throws {
        deleteSendSendView = sendView
        try deleteSendResult.get()
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

    func sendListPublisher() -> AsyncThrowingPublisher<AnyPublisher<[SendListSection], Error>> {
        sendListSubject
            .eraseToAnyPublisher()
            .values
    }
}
