import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockSendDataStore: SendDataStore {
    var deleteAllSendsUserId: String?

    var deleteSendId: String?
    var deleteSendUserId: String?

    var sendSubject = CurrentValueSubject<[Send], Error>([])

    var replaceSendsValue: [Send]?
    var replaceSendsUserId: String?

    var upsertSendValue: Send?
    var upsertSendUserId: String?

    func deleteAllSends(userId: String) async throws {
        deleteAllSendsUserId = userId
    }

    func deleteSend(id: String, userId: String) async throws {
        deleteSendId = id
        deleteSendUserId = userId
    }

    func sendPublisher(userId: String) -> AnyPublisher<[Send], Error> {
        sendSubject.eraseToAnyPublisher()
    }

    func replaceSends(_ sends: [Send], userId: String) async throws {
        replaceSendsValue = sends
        replaceSendsUserId = userId
    }

    func upsertSend(_ send: Send, userId: String) async throws {
        upsertSendValue = send
        upsertSendUserId = userId
    }
}
