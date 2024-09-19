import Foundation

// MARK: - AuthenticatorBridgeItemService

/// A service that provides a number of convenience methods for working with the shared
/// `AuthenticatorBridgeItemData` objects.
///
public protocol AuthenticatorBridgeItemService {
    /// Removes all items that are owned by the specific userId
    ///
    /// - Parameter userId: the id of the user for which to delete all items.
    ///
    func deleteAllForUserId(_ userId: String) async throws

    /// Fetches all items that are owned by the specific userId
    ///
    /// - Parameter userId: the id of the user for which to fetch items.
    ///
    func fetchAllForUserId(_ userId: String) async throws -> [AuthenticatorBridgeItemDataModel]

    /// Inserts the list of items into the store for the given userId.
    ///
    /// - Parameters:
    ///   - items: The list of `AuthenticatorBridgeItemDataModel` to be inserted into the store.
    ///   - userId: the id of the user for which to insert the items.
    ///
    func insertItems(_ items: [AuthenticatorBridgeItemDataModel],
                     forUserId userId: String) async throws

    /// Deletes all existing items for a given user and inserts new items for the list of items provided.
    ///
    /// - Parameters:
    ///   - items: The new items to be inserted into the store
    ///   - userId: The userId of the items to be removed and then replaces with items.
    ///
    func replaceAllItems(with items: [AuthenticatorBridgeItemDataModel],
                         forUserId userId: String) async throws
}

/// A concrete implementation of the `AuthenticatorBridgeItemService` protocol.
///
public class DefaultAuthenticatorBridgeItemService: AuthenticatorBridgeItemService {
    // MARK: Properties

    /// Cryptography service for encrypting/decrypting items.
    let cryptoService: SharedCryptographyService

    /// The CoreData store for working with shared data.
    let dataStore: AuthenticatorBridgeDataStore

    /// The keychain repository for working with the shared key.
    let sharedKeychainRepository: SharedKeychainRepository

    // MARK: Initialization

    /// Initialize a `DefaultAuthenticatorBridgeItemService`
    ///
    /// - Parameters:
    ///   - cryptoService: Cryptography service for encrypting/decrypting items.
    ///   - dataStore: The CoreData store for working with shared data
    ///   - sharedKeychainRepository: The keychain repository for working with the shared key.
    ///
    public init(cryptoService: SharedCryptographyService,
                dataStore: AuthenticatorBridgeDataStore,
                sharedKeychainRepository: SharedKeychainRepository) {
        self.cryptoService = cryptoService
        self.dataStore = dataStore
        self.sharedKeychainRepository = sharedKeychainRepository
    }

    // MARK: Methods

    /// Removes all items that are owned by the specific userId
    ///
    /// - Parameter userId: the id of the user for which to delete all items.
    ///
    public func deleteAllForUserId(_ userId: String) async throws {
        try await dataStore.executeBatchDelete(AuthenticatorBridgeItemData.deleteByUserIdRequest(userId: userId))
    }

    /// Fetches all items that are owned by the specific userId
    ///
    /// - Parameter userId: the id of the user for which to fetch items.
    ///
    public func fetchAllForUserId(_ userId: String) async throws -> [AuthenticatorBridgeItemDataModel] {
        let fetchRequest = AuthenticatorBridgeItemData.fetchByUserIdRequest(userId: userId)
        let result = try dataStore.backgroundContext.fetch(fetchRequest)
        let encryptedItems = result.compactMap { data in
            data.model
        }
        return try await cryptoService.decryptAuthenticatorItems(encryptedItems)
    }

    /// Inserts the list of items into the store for the given userId.
    ///
    /// - Parameters:
    ///   - items: The list of `AuthenticatorBridgeItemDataModel` to be inserted into the store.
    ///   - userId: the id of the user for which to insert the items.
    ///
    public func insertItems(_ items: [AuthenticatorBridgeItemDataModel],
                            forUserId userId: String) async throws {
        let encryptedItems = try await cryptoService.encryptAuthenticatorItems(items)
        try await dataStore.executeBatchInsert(
            AuthenticatorBridgeItemData.batchInsertRequest(objects: encryptedItems, userId: userId)
        )
    }

    /// Deletes all existing items for a given user and inserts new items for the list of items provided.
    ///
    /// - Parameters:
    ///   - items: The new items to be inserted into the store
    ///   - userId: The userId of the items to be removed and then replaces with items.
    ///
    public func replaceAllItems(with items: [AuthenticatorBridgeItemDataModel],
                                forUserId userId: String) async throws {
        let encryptedItems = try await cryptoService.encryptAuthenticatorItems(items)
        let deleteRequest = AuthenticatorBridgeItemData.deleteByUserIdRequest(userId: userId)
        let insertRequest = try AuthenticatorBridgeItemData.batchInsertRequest(
            objects: encryptedItems,
            userId: userId
        )
        try await dataStore.executeBatchReplace(
            deleteRequest: deleteRequest,
            insertRequest: insertRequest
        )
    }
}
