import AuthenticatorBridgeKit
import BitwardenShared

class MockAuthenticatorBridgeItemService: AuthenticatorBridgeItemService {
    var storedItems: [String: [AuthenticatorBridgeItemDataModel]] = [:]

    func deleteAllForUserId(_ userId: String) async throws {
        storedItems[userId] = []
    }

    func fetchAllForUserId(_ userId: String) async throws -> [AuthenticatorBridgeItemDataModel] {
        storedItems[userId] ?? []
    }

    func insertItems(_ items: [AuthenticatorBridgeItemDataModel], forUserId userId: String) async throws {
        storedItems[userId] = items
    }

    func replaceAllItems(with items: [AuthenticatorBridgeItemDataModel], forUserId userId: String) async throws {
        storedItems[userId] = items
    }
}
