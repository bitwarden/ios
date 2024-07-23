import Foundation

@testable import BitwardenShared

class MockEventService: EventService {
    var collectEventType: EventType?
    var collectCipherId: String?
    var uploadCalled = false

    func collect(eventType: EventType, cipherId: String?) async {
        collectEventType = eventType
        collectCipherId = cipherId
    }

    func upload() async {
        uploadCalled = true
    }
}
