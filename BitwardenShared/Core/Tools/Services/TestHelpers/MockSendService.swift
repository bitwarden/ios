import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

// MARK: - MockSendService

class MockSendService: SendService {
    // MARK: Properties

    var addFileSendData: Data?
    var addFileSendSend: Send?
    var addFileSendResult: Result<Void, Error> = .success(())

    var addTextSendSend: Send?
    var addTextSendResult: Result<Void, Error> = .success(())

    var deleteSendSend: Send?
    var deleteSendResult: Result<Void, Error> = .success(())

    var updateSendSend: Send?
    var updateSendResult: Result<Void, Error> = .success(())

    var replaceSendsSends: [SendResponseModel]?
    var replaceSendsUserId: String?

    var sendsSubject = CurrentValueSubject<[Send], Error>([])

    // MARK: Methods

    func addFileSend(_ send: Send, data: Data) async throws {
        addFileSendData = data
        addFileSendSend = send
        try addFileSendResult.get()
    }

    func addTextSend(_ send: Send) async throws {
        addTextSendSend = send
        try addTextSendResult.get()
    }

    func deleteSend(_ send: Send) async throws {
        deleteSendSend = send
        try deleteSendResult.get()
    }

    func updateSend(_ send: Send) async throws {
        updateSendSend = send
        try updateSendResult.get()
    }

    func replaceSends(_ sends: [SendResponseModel], userId: String) async throws {
        replaceSendsSends = sends
        replaceSendsUserId = userId
    }

    func sendsPublisher() async throws -> AnyPublisher<[Send], Error> {
        sendsSubject.eraseToAnyPublisher()
    }
}
