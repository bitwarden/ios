import AuthenticatorBridgeKit
import BitwardenShared
import Combine

class MockAuthenticatorBridgeItemService: AuthenticatorBridgeItemService {
    var errorToThrow: Error?
    var replaceAllCalled = false
    var sharedItemsSubject = CurrentValueSubject<[AuthenticatorBridgeItemDataView], Error>([])
    var storedItems: [String: [AuthenticatorBridgeItemDataView]] = [:]
    var syncOn = false
    var tempItem: AuthenticatorBridgeItemDataView?

    func deleteAllForUserId(_ userId: String) async throws {
        guard errorToThrow == nil else { throw errorToThrow! }
        storedItems[userId] = []
    }

    func fetchAllForUserId(_ userId: String) async throws -> [AuthenticatorBridgeItemDataView] {
        guard errorToThrow == nil else { throw errorToThrow! }
        return storedItems[userId] ?? []
    }

    func fetchTemporaryItem() async throws -> AuthenticatorBridgeItemDataView? {
        guard errorToThrow == nil else { throw errorToThrow! }
        return tempItem
    }

    func insertTemporaryItem(_ item: AuthenticatorBridgeItemDataView) async throws {
        guard errorToThrow == nil else { throw errorToThrow! }
        tempItem = item
    }

    func insertItems(_ items: [AuthenticatorBridgeItemDataView], forUserId userId: String) async throws {
        guard errorToThrow == nil else { throw errorToThrow! }
        storedItems[userId] = items
    }

    func isSyncOn() async -> Bool {
        syncOn
    }

    func replaceAllItems(with items: [AuthenticatorBridgeItemDataView], forUserId userId: String) async throws {
        guard errorToThrow == nil else { throw errorToThrow! }
        storedItems[userId] = items
        replaceAllCalled = true
    }

    func sharedItemsPublisher() async throws ->
        AnyPublisher<[AuthenticatorBridgeKit.AuthenticatorBridgeItemDataView], any Error> {
        guard errorToThrow == nil else { throw errorToThrow! }

        return sharedItemsSubject.eraseToAnyPublisher()
    }
}
