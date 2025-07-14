import AuthenticatorBridgeKit
import Combine

public class MockAuthenticatorBridgeItemService: AuthenticatorBridgeItemService {
    public var errorToThrow: Error?
    public var replaceAllCalled = false
    public var sharedItemsError: Error?
    public var sharedItemsSubject = CurrentValueSubject<[AuthenticatorBridgeItemDataView], Error>([])
    public var storedItems: [String: [AuthenticatorBridgeItemDataView]] = [:]
    public var syncOn = false
    public var tempItem: AuthenticatorBridgeItemDataView?

    public init() {}

    public func deleteAll() async throws {
        guard errorToThrow == nil else { throw errorToThrow! }
        storedItems = [:]
    }

    public func deleteAllForUserId(_ userId: String) async throws {
        guard errorToThrow == nil else { throw errorToThrow! }
        storedItems[userId] = []
    }

    public func fetchAllForUserId(_ userId: String) async throws -> [AuthenticatorBridgeItemDataView] {
        guard errorToThrow == nil else { throw errorToThrow! }
        return storedItems[userId] ?? []
    }

    public func fetchTemporaryItem() async throws -> AuthenticatorBridgeItemDataView? {
        guard errorToThrow == nil else { throw errorToThrow! }
        return tempItem
    }

    public func insertTemporaryItem(_ item: AuthenticatorBridgeItemDataView) async throws {
        guard errorToThrow == nil else { throw errorToThrow! }
        tempItem = item
    }

    public func insertItems(_ items: [AuthenticatorBridgeItemDataView], forUserId userId: String) async throws {
        guard errorToThrow == nil else { throw errorToThrow! }
        storedItems[userId] = items
    }

    public func isSyncOn() async -> Bool {
        syncOn
    }

    public func replaceAllItems(with items: [AuthenticatorBridgeItemDataView], forUserId userId: String) async throws {
        guard errorToThrow == nil else { throw errorToThrow! }
        storedItems[userId] = items
        replaceAllCalled = true
    }

    public func sharedItemsPublisher() async throws ->
        AnyPublisher<[AuthenticatorBridgeKit.AuthenticatorBridgeItemDataView], any Error> {
        guard sharedItemsError == nil else { throw sharedItemsError! }

        return sharedItemsSubject.eraseToAnyPublisher()
    }
}
