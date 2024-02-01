import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

// MARK: - MockSendService

class MockSendService: SendService {
    // MARK: Properties

    var addFileSendData: Data?
    var addFileSendSend: Send?
    var addFileSendResult: Result<Send, Error> = .success(.fixture())

    var addTextSendSend: Send?
    var addTextSendResult: Result<Send, Error> = .success(.fixture())

    var deleteSendSend: Send?
    var deleteSendResult: Result<Void, Error> = .success(())

    var deleteSendWithLocalStorageId: String?
    var deleteSendWithLocalStorageResult: Result<Void, Error> = .success(())

    var fetchSendId: String?
    var fetchSendResult: Result<Send?, Error> = .success(nil)

    var updateSendSend: Send?
    var updateSendResult: Result<Send, Error> = .success(.fixture())

    var removePasswordFromSendResult: Result<Send, Error> = .success(.fixture())
    var removePasswordFromSendSend: Send?

    var replaceSendsSends: [SendResponseModel]?
    var replaceSendsUserId: String?

    var syncSendWithServerId: String?
    var syncSendWithServerResult: Result<Void, Error> = .success(())

    var sendsSubject = CurrentValueSubject<[Send], Error>([])

    // MARK: Methods

    func addFileSend(_ send: Send, data: Data) async throws -> Send {
        addFileSendData = data
        addFileSendSend = send
        return try addFileSendResult.get()
    }

    func addTextSend(_ send: Send) async throws -> Send {
        addTextSendSend = send
        return try addTextSendResult.get()
    }

    func deleteSend(_ send: Send) async throws {
        deleteSendSend = send
        try deleteSendResult.get()
    }

    func deleteSendWithLocalStorage(id: String) async throws {
        deleteSendWithLocalStorageId = id
        return try deleteSendWithLocalStorageResult.get()
    }

    func fetchSend(id: String) async throws -> BitwardenSdk.Send? {
        fetchSendId = id
        return try fetchSendResult.get()
    }

    func updateSend(_ send: Send) async throws -> Send {
        updateSendSend = send
        return try updateSendResult.get()
    }

    func removePasswordFromSend(_ send: Send) async throws -> Send {
        removePasswordFromSendSend = send
        return try removePasswordFromSendResult.get()
    }

    func replaceSends(_ sends: [SendResponseModel], userId: String) async throws {
        replaceSendsSends = sends
        replaceSendsUserId = userId
    }

    func syncSendWithServer(id: String) async throws {
        syncSendWithServerId = id
        return try syncSendWithServerResult.get()
    }

    func sendsPublisher() async throws -> AnyPublisher<[Send], Error> {
        sendsSubject.eraseToAnyPublisher()
    }
}
