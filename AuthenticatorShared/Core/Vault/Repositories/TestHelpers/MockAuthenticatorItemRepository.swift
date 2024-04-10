import Combine
import Foundation

@testable import AuthenticatorShared

class MockAuthenticatorItemRepository: AuthenticatorItemRepository {

    // MARK: Properties

    var addAuthenticatorItemAuthenticatorItems = [AuthenticatorItemView]()
    var addAuthenticatorItemResult: Result<Void, Error> = .success(())

    var deletedAuthenticatorItem = [String]()
    var deleteAuthenticatorItemResult: Result<Void, Error> = .success(())

    var fetchAllAuthenticatorItemsResult: Result<[AuthenticatorItemView], Error> = .success([])

    var fetchAuthenticatorItemId: String?
    var fetchAuthenticatorItemResult: Result<AuthenticatorItemView?, Error> = .success(nil)

    var refreshTOTPCodeResult: Result<TOTPCodeModel, Error> = .success(
        TOTPCodeModel(code: .base32Key, codeGenerationDate: .now, period: 30)
    )
    var refreshedTOTPKeyConfig: TOTPKeyModel?

    var authenticatorItemDetailsSubject = CurrentValueSubject<AuthenticatorItemView?, Error>(nil)
    var itemListSubject = CurrentValueSubject<[ItemListSection], Error>([])

    var updateAuthenticatorItemItems = [AuthenticatorItemView]()
    var updateAuthenticatorItemResult: Result<Void, Error> = .success(())

    // MARK: Methods

    func addAuthenticatorItem(_ authenticatorItem: AuthenticatorItemView) async throws {
        addAuthenticatorItemAuthenticatorItems.append(authenticatorItem)
        try addAuthenticatorItemResult.get()
    }

    func deleteAuthenticatorItem(_ id: String) async throws {
        deletedAuthenticatorItem.append(id)
        try deleteAuthenticatorItemResult.get()
    }

    func fetchAllAuthenticatorItems() async throws -> [AuthenticatorShared.AuthenticatorItemView] {
        return try fetchAllAuthenticatorItemsResult.get()
    }

    func fetchAuthenticatorItem(withId id: String) async throws -> AuthenticatorItemView? {
        fetchAuthenticatorItemId = id
        return try fetchAuthenticatorItemResult.get()
    }

    func refreshTotpCode(for key: TOTPKeyModel) async throws -> AuthenticatorShared.TOTPCodeModel {
        refreshedTOTPKeyConfig = key
        return try refreshTOTPCodeResult.get()
    }

    func authenticatorItemDetailsPublisher(
        id: String
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<AuthenticatorItemView?, Error>> {
        authenticatorItemDetailsSubject.eraseToAnyPublisher().values
    }

    func itemListPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[ItemListSection], Error>> {
        itemListSubject.eraseToAnyPublisher().values
    }

    func updateAuthenticatorItem(_ authenticatorItem: AuthenticatorItemView) async throws {
        updateAuthenticatorItemItems.append(authenticatorItem)
        try updateAuthenticatorItemResult.get()
    }
}
