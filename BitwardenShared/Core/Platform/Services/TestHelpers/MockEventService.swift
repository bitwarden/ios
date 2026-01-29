import Foundation

@testable import BitwardenShared

class MockEventService: EventService {
    var collectEventType: EventType?
    var collectCipherId: String?
    var collectOrganizationId: String?
    var uploadCalled = false

    func collect(eventType: EventType, cipherId: String?, organizationId: String?) async {
        collectEventType = eventType
        collectCipherId = cipherId
        collectOrganizationId = organizationId
    }

    func upload() async {
        uploadCalled = true
    }
}
