import Combine
import Foundation

@testable import AuthenticatorShared

class MockAuthenticatorItemRepository: AuthenticatorItemRepository {
    // MARK: Properties

    var addAuthItemAuthItems = [AuthenticatorItemView]()
    var addAuthenticatorItemResult: Result<Void, Error> = .success(())

    var deletedAuthenticatorItem = [String]()
    var deleteAuthenticatorItemResult: Result<Void, Error> = .success(())

    var fetchAllAuthenticatorItemsResult: Result<[AuthenticatorItemView], Error> = .success([])

    var fetchAuthenticatorItemId: String?
    var fetchAuthenticatorItemResult: Result<AuthenticatorItemView?, Error> = .success(nil)

    var refreshTotpCodesResult: Result<[ItemListItem], Error> = .success([])
    var refreshedTotpTime: Date?
    var refreshedTotpCodes: [ItemListItem] = []

    var authenticatorItemDetailsSubject = CurrentValueSubject<AuthenticatorItemView?, Error>(nil)
    var itemListSubject = CurrentValueSubject<[ItemListSection], Error>([])

    var searchItemListSubject = CurrentValueSubject<[ItemListItem], Error>([])

    var timeProvider: TimeProvider = MockTimeProvider(.currentTime)

    var updateAuthenticatorItemItems = [AuthenticatorItemView]()
    var updateAuthenticatorItemResult: Result<Void, Error> = .success(())

    // MARK: Methods

    func addAuthenticatorItem(_ authenticatorItem: AuthenticatorItemView) async throws {
        addAuthItemAuthItems.append(authenticatorItem)
        try addAuthenticatorItemResult.get()
    }

    func deleteAuthenticatorItem(_ id: String) async throws {
        deletedAuthenticatorItem.append(id)
        try deleteAuthenticatorItemResult.get()
    }

    func fetchAllAuthenticatorItems() async throws -> [AuthenticatorItemView] {
        try fetchAllAuthenticatorItemsResult.get()
    }

    func fetchAuthenticatorItem(withId id: String) async throws -> AuthenticatorItemView? {
        fetchAuthenticatorItemId = id
        return try fetchAuthenticatorItemResult.get()
    }

    func refreshTotpCodes(on items: [ItemListItem]) async throws -> [ItemListItem] {
        refreshedTotpTime = timeProvider.presentTime
        refreshedTotpCodes = items
        return try refreshTotpCodesResult.get()
    }

    func updateAuthenticatorItem(_ authenticatorItem: AuthenticatorItemView) async throws {
        updateAuthenticatorItemItems.append(authenticatorItem)
        try updateAuthenticatorItemResult.get()
    }

    func authenticatorItemDetailsPublisher(
        id: String
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<AuthenticatorItemView?, Error>> {
        authenticatorItemDetailsSubject.eraseToAnyPublisher().values
    }

    func itemListPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[ItemListSection], Error>> {
        itemListSubject.eraseToAnyPublisher().values
    }

    func searchItemListPublisher(
        searchText: String
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[ItemListItem], Error>> {
        searchItemListSubject.eraseToAnyPublisher().values
    }
}
