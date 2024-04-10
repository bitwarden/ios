import Combine
import Foundation

// MARK: - AuthenticatorItemService

/// A protocol for an `AuthenticatorItemService` which is the service layer
/// for managing a user's items
///
protocol AuthenticatorItemService {
    /// Add an item for the current user to local storage
    ///
    /// - Parameters:
    ///   - authenticatorItem: The item to add
    ///
    func addAuthenticatorItem(_ authenticatorItem: AuthenticatorItem) async throws

    /// Deletes an item for the current user from local storage
    ///
    /// - Parameters:
    ///   - id: The ID of the item to delete
    ///
    func deleteAuthenticatorItem(id: String) async throws

    /// Attempt to fetch an item for the current user
    ///
    /// - Parameters:
    ///   - id: The ID of the item to find
    /// - Returns: The item if it was found and `nil` if not
    ///
    func fetchAuthenticatorItem(withId id: String) async throws -> AuthenticatorItem?

    /// Fetches all items for the current user
    ///
    /// - Returns: The items belonging to the current user
    ///
    func fetchAllAuthenticatorItems() async throws -> [AuthenticatorItem]

    /// Updates an item for the current user
    ///
    /// - Parameters:
    ///   - authenticatorItem: The item to update
    ///
    func updateAuthenticatorItem(_ authenticatorItem: AuthenticatorItem) async throws

    // MARK: Publishers

    /// A publisher for the list of items for the current user
    ///
    /// - Returns: The list of items
    ///
    func authenticatorItemsPublisher() async throws -> AnyPublisher<[AuthenticatorItem], Error>
}

// MARK: - DefaultAuthenticatorItemService

class DefaultAuthenticatorItemService {
    // MARK: Properties

    // TODO: Generate this user ID and store it in the keychain?
    private let defaultUserId = "local"

    /// The data store for persisted items
    private let authenticatorItemDataStore: AuthenticatorItemDataStore

    // MARK: Initialization

    /// Initializes a `DefaultAuthenticatorItemService`
    ///
    /// - Parameters:
    ///   - authenticatorItemDataStore: The data store for persisted items
    ///
    init(
        authenticatorItemDataStore: AuthenticatorItemDataStore
    ) {
        self.authenticatorItemDataStore = authenticatorItemDataStore
    }
}

extension DefaultAuthenticatorItemService: AuthenticatorItemService {
    func addAuthenticatorItem(_ authenticatorItem: AuthenticatorItem) async throws {
        try await authenticatorItemDataStore.upsertAuthenticatorItem(authenticatorItem, userId: defaultUserId)
    }

    func deleteAuthenticatorItem(id: String) async throws {
        try await authenticatorItemDataStore.deleteAuthenticatorItem(id: id, userId: defaultUserId)
    }

    func fetchAuthenticatorItem(withId id: String) async throws -> AuthenticatorItem? {
        try await authenticatorItemDataStore.fetchAuthenticatorItem(withId: id, userId: defaultUserId)
    }

    func fetchAllAuthenticatorItems() async throws -> [AuthenticatorItem] {
        try await authenticatorItemDataStore.fetchAllAuthenticatorItems(userId: defaultUserId)
    }

    func updateAuthenticatorItem(_ authenticatorItem: AuthenticatorItem) async throws {
        try await authenticatorItemDataStore.upsertAuthenticatorItem(authenticatorItem, userId: defaultUserId)
    }

    func authenticatorItemsPublisher() async throws -> AnyPublisher<[AuthenticatorItem], Error> {
        authenticatorItemDataStore.authenticatorItemPublisher(userId: defaultUserId)
    }
}
