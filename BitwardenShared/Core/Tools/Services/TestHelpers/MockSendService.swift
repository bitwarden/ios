@testable import BitwardenShared

class MockSendService: SendService {
    var replaceSendsSends: [SendResponseModel]?
    var replaceSendsUserId: String?

    func replaceSends(_ sends: [SendResponseModel], userId: String) async throws {
        replaceSendsSends = sends
        replaceSendsUserId = userId
    }
}
