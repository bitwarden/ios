import AuthenticatorBridgeKit
import BitwardenShared
import Combine

class MockAuthenticatorBridgeItemService: AuthenticatorBridgeItemService {
    var replaceAllCalled = false
    var sharedItemsPublisherError: Error?
    var sharedItemsSubject = CurrentValueSubject<[AuthenticatorBridgeItemDataView], Error>([])
    var storedItems: [String: [AuthenticatorBridgeItemDataView]] = [:]
    var syncOn = false

    func deleteAllForUserId(_ userId: String) async throws {
        storedItems[userId] = []
    }

    func fetchAllForUserId(_ userId: String) async throws -> [AuthenticatorBridgeItemDataView] {
        storedItems[userId] ?? []
    }

    func insertItems(_ items: [AuthenticatorBridgeItemDataView], forUserId userId: String) async throws {
        storedItems[userId] = items
    }

    func isSyncOn() async throws -> Bool {
        syncOn
    }

    func replaceAllItems(with items: [AuthenticatorBridgeItemDataView], forUserId userId: String) async throws {
        storedItems[userId] = items
        replaceAllCalled = true
    }

    func sharedItemsPublisher() async throws ->
        AnyPublisher<[AuthenticatorBridgeKit.AuthenticatorBridgeItemDataView], any Error> {
        if let sharedItemsPublisherError {
            throw sharedItemsPublisherError
        }
        return sharedItemsSubject.eraseToAnyPublisher()
    }
}
