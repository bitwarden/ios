import Combine

@testable import AuthenticatorShared

class MockAuthenticatorItemDataStore: AuthenticatorItemDataStore {
    var deleteAllAuthenticatorItemsUserId: String?

    var deleteAuthenticatorItemId: String?
    var deleteAuthenticatorItemUserId: String?

    var fetchAllAuthenticatorItemsUserId: String?
    var fetchAllAuthenticatorItemsResult: Result<[AuthenticatorItem], Error> = .success([])

    var fetchAuthenticatorItemId: String?
    var fetchAuthenticatorItemResult: AuthenticatorItem?

    var authenticatorItemSubject = CurrentValueSubject<[AuthenticatorItem], Error>([])

    var replaceAuthenticatorItemsValue: [AuthenticatorItem]?
    var replaceAuthenticatorItemsUserId: String?

    var upsertAuthenticatorItemValue: AuthenticatorItem?
    var upsertAuthenticatorItemUserId: String?

    func deleteAllAuthenticatorItems(userId: String) async throws {
        deleteAllAuthenticatorItemsUserId = userId
    }

    func deleteAuthenticatorItem(id: String, userId: String) async throws {
        deleteAuthenticatorItemId = id
        deleteAuthenticatorItemUserId = userId
    }

    func fetchAllAuthenticatorItems(userId: String) async throws -> [AuthenticatorItem] {
        fetchAllAuthenticatorItemsUserId = userId
        return try fetchAllAuthenticatorItemsResult.get()
    }

    func fetchAuthenticatorItem(withId id: String, userId _: String) async -> AuthenticatorItem? {
        fetchAuthenticatorItemId = id
        return fetchAuthenticatorItemResult
    }

    func authenticatorItemPublisher(userId _: String) -> AnyPublisher<[AuthenticatorItem], Error> {
        authenticatorItemSubject.eraseToAnyPublisher()
    }

    func replaceAuthenticatorItems(_ authenticatorItems: [AuthenticatorItem], userId: String) async throws {
        replaceAuthenticatorItemsValue = authenticatorItems
        replaceAuthenticatorItemsUserId = userId
    }

    func upsertAuthenticatorItem(_ authenticatorItem: AuthenticatorItem, userId: String) async throws {
        upsertAuthenticatorItemValue = authenticatorItem
        upsertAuthenticatorItemUserId = userId
    }
}
