import AuthenticatorBridgeKit
import BitwardenShared

class MockAuthenticatorBridgeItemService: AuthenticatorBridgeItemService {
    var replaceAllCalled = false
    var storedItems: [String: [AuthenticatorBridgeItemDataView]] = [:]

    func deleteAllForUserId(_ userId: String) async throws {
        storedItems[userId] = []
    }

    func fetchAllForUserId(_ userId: String) async throws -> [AuthenticatorBridgeItemDataView] {
        storedItems[userId] ?? []
    }

    func insertItems(_ items: [AuthenticatorBridgeItemDataView], forUserId userId: String) async throws {
        storedItems[userId] = items
    }

    func replaceAllItems(with items: [AuthenticatorBridgeItemDataView], forUserId userId: String) async throws {
        storedItems[userId] = items
        replaceAllCalled = true
    }
}
