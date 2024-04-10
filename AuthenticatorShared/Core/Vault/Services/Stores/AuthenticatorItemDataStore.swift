import Combine
import CoreData

// MARK: - AuthenticatorItemDataStore

/// A protocol for a data store that handles performing data requests for authenticator items.
///
protocol AuthenticatorItemDataStore: AnyObject {
    /// Deletes all `AuthenticatorItem` objects for a specific user.
    ///
    /// - Parameter userId: The user ID of the user associated with the objects to delete.
    ///
    func deleteAllAuthenticatorItems(userId: String) async throws

    /// Deletes a `AuthenticatorItem` by ID for a user.
    ///
    /// - Parameters:
    ///   - id: The ID of the `AuthenticatorItem` to delete.
    ///   - userId: The user ID of the user associated with the object to delete.
    ///
    func deleteAuthenticatorItem(id: String, userId: String) async throws

    /// Attempt to fetch an authenticator item with the given id.
    ///
    /// - Parameters:
    ///   - id: The id of the authenticator item to find.
    ///   - userId: The user ID of the user associated with the authenticator items.
    /// - Returns: The authenticator item if it was found and `nil` if not.
    ///
    func fetchAuthenticatorItem(withId id: String, userId: String) async throws -> AuthenticatorItem?

    /// Fetches all the authenticator items belonging to the specified user id.
    ///
    /// - Parameter userId: The id of the user associated with the authenticator items.
    /// - Returns: The authenticator items associated with the user id.
    ///
    func fetchAllAuthenticatorItems(userId: String) async throws -> [AuthenticatorItem]

    /// A publisher for a user's authenticator item objects.
    ///
    /// - Parameter userId: The user ID of the user to associated with the objects to fetch.
    /// - Returns: A publisher for the user's authenticator items.
    ///
    func authenticatorItemPublisher(userId: String) -> AnyPublisher<[AuthenticatorItem], Error>

    /// Replaces a list of `AuthenticatorItem` objects for a user.
    ///
    /// - Parameters:
    ///   - authenticatorItems: The list of authenticator items to replace any existing authenticator items.
    ///   - userId: The user ID of the user associated with the authenticator items.
    ///
    func replaceAuthenticatorItems(_ authenticatorItems: [AuthenticatorItem], userId: String) async throws

    /// Inserts or updates an authenticator item for a user.
    ///
    /// - Parameters:
    ///   - authenticatorItem: The authenticator item to insert or update.
    ///   - userId: The user ID of the user associated with the authenticator item.
    ///
    func upsertAuthenticatorItem(_ authenticatorItem: AuthenticatorItem, userId: String) async throws
}

extension DataStore: AuthenticatorItemDataStore {
    func deleteAllAuthenticatorItems(userId: String) async throws {
        try await executeBatchDelete(AuthenticatorItemData.deleteByUserIdRequest(userId: userId))
    }

    func deleteAuthenticatorItem(id: String, userId: String) async throws {
        try await backgroundContext.performAndSave {
            let results = try self.backgroundContext.fetch(
                AuthenticatorItemData.fetchByIdRequest(id: id, userId: userId)
            )
            for result in results {
                self.backgroundContext.delete(result)
            }
        }
    }

    func fetchAuthenticatorItem(withId id: String, userId: String) async throws -> AuthenticatorItem? {
        try await backgroundContext.perform {
            try self.backgroundContext.fetch(AuthenticatorItemData.fetchByIdRequest(id: id, userId: userId))
                .compactMap(AuthenticatorItem.init)
                .first
        }
    }

    func fetchAllAuthenticatorItems(userId: String) async throws -> [AuthenticatorItem] {
        try await backgroundContext.perform {
            let fetchRequest = AuthenticatorItemData.fetchByUserIdRequest(userId: userId)
            return try self.backgroundContext.fetch(fetchRequest).map(AuthenticatorItem.init)
        }
    }

    func authenticatorItemPublisher(userId: String) -> AnyPublisher<[AuthenticatorItem], Error> {
        let fetchRequest = AuthenticatorItemData.fetchByUserIdRequest(userId: userId)
        // A sort descriptor is needed by `NSFetchedResultsController`.
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \AuthenticatorItemData.id, ascending: true)]
        return FetchedResultsPublisher(
            context: persistentContainer.viewContext,
            request: fetchRequest
        )
        .tryMap { try $0.map(AuthenticatorItem.init) }
        .eraseToAnyPublisher()
    }

    func replaceAuthenticatorItems(_ authenticatorItems: [AuthenticatorItem], userId: String) async throws {
        let deleteRequest = AuthenticatorItemData.deleteByUserIdRequest(userId: userId)
        let insertRequest = try AuthenticatorItemData.batchInsertRequest(objects: authenticatorItems, userId: userId)
        try await executeBatchReplace(
            deleteRequest: deleteRequest,
            insertRequest: insertRequest
        )
    }

    func upsertAuthenticatorItem(_ authenticatorItem: AuthenticatorItem, userId: String) async throws {
        try await backgroundContext.performAndSave {
            _ = try AuthenticatorItemData(
                context: self.backgroundContext,
                userId: userId,
                authenticatorItem: authenticatorItem
            )
        }
    }
}
