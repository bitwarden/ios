import BitwardenSdk
import Combine

@testable import BitwardenShared

// MARK: - MockSendService

class MockSendService: SendService {
    // MARK: Properties

    var addSendSend: Send?
    var addSendResult: Result<Void, Error> = .success(())

    var replaceSendsSends: [SendResponseModel]?
    var replaceSendsUserId: String?

    var sendsSubject = CurrentValueSubject<[Send], Error>([])

    // MARK: Methods

    func addSend(_ send: Send) async throws {
        addSendSend = send
        try addSendResult.get()
    }

    func replaceSends(_ sends: [SendResponseModel], userId: String) async throws {
        replaceSendsSends = sends
        replaceSendsUserId = userId
    }

    func sendsPublisher() async throws -> AnyPublisher<[Send], Error> {
        sendsSubject.eraseToAnyPublisher()
    }
}
