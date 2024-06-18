import Foundation

@testable import BitwardenShared

class MockEventService: EventService {
    var collectEventType: EventType?
    var collectCipherId: String?
    var collectUploadImmediately: Bool?

    func collect(eventType: EventType, cipherId: String?, uploadImmediately: Bool) async {
        collectEventType = eventType
        collectCipherId = cipherId
        collectUploadImmediately = uploadImmediately
    }
}
