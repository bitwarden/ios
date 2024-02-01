import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

// MARK: - MockSendRepository

class MockSendRepository: SendRepository {
    // MARK: Properties

    var doesActivateAccountHavePremiumResult: Result<Bool, Error> = .success(true)

    var doesActiveAccountHaveVerifiedEmailResult: Result<Bool, Error> = .success(true)

    var fetchSyncCalled = false
    var fetchSyncIsManualRefresh: Bool?
    var fetchSyncResult: Result<Void, Error> = .success(())

    var searchSendSearchText: String?
    var searchSendType: BitwardenShared.SendType?
    var searchSendSubject = CurrentValueSubject<[SendListItem], Error>([])

    var sendListSubject = CurrentValueSubject<[SendListSection], Error>([])

    var sendTypeListPublisherType: BitwardenShared.SendType?
    var sendTypeListSubject = CurrentValueSubject<[SendListItem], Error>([])

    var addFileSendResult: Result<SendView, Error> = .success(.fixture())
    var addFileSendData: Data?
    var addFileSendSendView: SendView?

    var addTextSendResult: Result<SendView, Error> = .success(.fixture())
    var addTextSendSendView: SendView?

    var deleteSendResult: Result<Void, Error> = .success(())
    var deleteSendSendView: SendView?

    var removePasswordFromSendResult: Result<SendView, Error> = .success(.fixture())
    var removePasswordFromSendSendView: SendView?

    var updateSendResult: Result<SendView, Error> = .success(.fixture())
    var updateSendSendView: SendView?

    var shareURLResult: Result<URL?, Error> = .success(.example)
    var shareURLSendView: SendView?

    // MARK: Methods

    func addFileSend(_ sendView: SendView, data: Data) async throws -> SendView {
        addFileSendSendView = sendView
        addFileSendData = data
        return try addFileSendResult.get()
    }

    func addTextSend(_ sendView: SendView) async throws -> SendView {
        addTextSendSendView = sendView
        return try addTextSendResult.get()
    }

    func deleteSend(_ sendView: SendView) async throws {
        deleteSendSendView = sendView
        try deleteSendResult.get()
    }

    func removePassword(from sendView: SendView) async throws -> SendView {
        removePasswordFromSendSendView = sendView
        return try removePasswordFromSendResult.get()
    }

    func updateSend(_ sendView: SendView) async throws -> SendView {
        updateSendSendView = sendView
        return try updateSendResult.get()
    }

    func doesActiveAccountHavePremium() async throws -> Bool {
        try doesActivateAccountHavePremiumResult.get()
    }

    func doesActiveAccountHaveVerifiedEmail() async throws -> Bool {
        try doesActiveAccountHaveVerifiedEmailResult.get()
    }

    func fetchSync(isManualRefresh: Bool) async throws {
        fetchSyncCalled = true
        fetchSyncIsManualRefresh = isManualRefresh
        try fetchSyncResult.get()
    }

    func searchSendPublisher(
        searchText: String,
        type: BitwardenShared.SendType?
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[SendListItem], Error>> {
        searchSendSearchText = searchText
        searchSendType = type
        return searchSendSubject.eraseToAnyPublisher().values
    }

    func sendListPublisher() -> AsyncThrowingPublisher<AnyPublisher<[SendListSection], Error>> {
        sendListSubject
            .eraseToAnyPublisher()
            .values
    }

    func sendTypeListPublisher(
        type: BitwardenShared.SendType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[SendListItem], Error>> {
        sendTypeListPublisherType = type
        return sendTypeListSubject
            .eraseToAnyPublisher()
            .values
    }

    func shareURL(for sendView: SendView) async throws -> URL? {
        shareURLSendView = sendView
        return try shareURLResult.get()
    }
}
