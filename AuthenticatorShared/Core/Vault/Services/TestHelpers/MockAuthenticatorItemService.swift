import Combine
import Foundation

@testable import AuthenticatorShared

class MockAuthenticatorItemService: AuthenticatorItemService {
    var addAuthenticatorItemAuthenticatorItems = [AuthenticatorItem]()
    var addAuthenticatorItemResult: Result<Void, Error> = .success(())

    var deleteAuthenticatorItemId: String?
    var deleteAuthenticatorItemResult: Result<Void, Error> = .success(())

    var fetchAuthenticatorItemId: String?
    var fetchAuthenticatorItemResult: Result<AuthenticatorItem?, Error> = .success(nil)

    var fetchAllAuthenticatorItemsResult: Result<[AuthenticatorItem], Error> = .success([])

    var updateAuthenticatorItemAuthenticatorItem: AuthenticatorItem?
    var updateAuthenticatorItemResult: Result<Void, Error> = .success(())

    var authenticatorItemsSubject = CurrentValueSubject<[AuthenticatorItem], Error>([])

    func addAuthenticatorItem(_ authenticatorItem: AuthenticatorShared.AuthenticatorItem) async throws {
        addAuthenticatorItemAuthenticatorItems.append(authenticatorItem)
        try addAuthenticatorItemResult.get()
    }

    func deleteAuthenticatorItem(id: String) async throws {
        deleteAuthenticatorItemId = id
        try deleteAuthenticatorItemResult.get()
    }

    func fetchAuthenticatorItem(withId id: String) async throws -> AuthenticatorShared.AuthenticatorItem? {
        fetchAuthenticatorItemId = id
        return try fetchAuthenticatorItemResult.get()
    }

    func fetchAllAuthenticatorItems() async throws -> [AuthenticatorShared.AuthenticatorItem] {
        try fetchAllAuthenticatorItemsResult.get()
    }

    func updateAuthenticatorItem(_ authenticatorItem: AuthenticatorShared.AuthenticatorItem) async throws {
        updateAuthenticatorItemAuthenticatorItem = authenticatorItem
        try updateAuthenticatorItemResult.get()
    }

    func authenticatorItemsPublisher() async throws -> AnyPublisher<[AuthenticatorShared.AuthenticatorItem], Error> {
        authenticatorItemsSubject.eraseToAnyPublisher()
    }
}
