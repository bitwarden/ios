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

    var updateSendSend: Send?
    var updateSendResult: Result<Send, Error> = .success(.fixture())

    var replaceSendsSends: [SendResponseModel]?
    var replaceSendsUserId: String?

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

    func updateSend(_ send: Send) async throws -> Send {
        updateSendSend = send
        return try updateSendResult.get()
    }

    func replaceSends(_ sends: [SendResponseModel], userId: String) async throws {
        replaceSendsSends = sends
        replaceSendsUserId = userId
    }

    func sendsPublisher() async throws -> AnyPublisher<[Send], Error> {
        sendsSubject.eraseToAnyPublisher()
    }
}
