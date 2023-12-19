import BitwardenSdk
import Combine
import CoreData

// MARK: - CollectionDataStore

/// A protocol for a data store that handles performing data requests for collections.
///
protocol CollectionDataStore: AnyObject {
    /// Deletes all `Collection` objects for a specific user.
    ///
    /// - Parameter userId: The user ID of the user associated with the objects to delete.
    ///
    func deleteAllCollections(userId: String) async throws

    /// Deletes a `Collection` by ID for a user.
    ///
    /// - Parameters:
    ///   - id: The ID of the `Collection` to delete.
    ///   - userId: The user ID of the user associated with the object to delete.
    ///
    func deleteCollection(id: String, userId: String) async throws

    /// A publisher for a user's collection objects.
    ///
    /// - Parameter userId: The user ID of the user to associated with the objects to fetch.
    /// - Returns: A publisher for the user's collections.
    ///
    func collectionPublisher(userId: String) -> AnyPublisher<[Collection], Error>

    /// Replaces a list of `Collection` objects for a user.
    ///
    /// - Parameters:
    ///   - collections: The list of collections to replace any existing collections.
    ///   - userId: The user ID of the user associated with the collections.
    ///
    func replaceCollections(_ collections: [Collection], userId: String) async throws

    /// Inserts or updates a collection for a user.
    ///
    /// - Parameters:
    ///   - collection: The collection to insert or update.
    ///   - userId: The user ID of the user associated with the collection.
    ///
    func upsertCollection(_ collection: Collection, userId: String) async throws
}

extension DataStore: CollectionDataStore {
    func deleteAllCollections(userId: String) async throws {
        try await executeBatchDelete(CollectionData.deleteByUserIdRequest(userId: userId))
    }

    func deleteCollection(id: String, userId: String) async throws {
        try await backgroundContext.performAndSave {
            let results = try self.backgroundContext.fetch(CollectionData.fetchByIdRequest(id: id, userId: userId))
            for result in results {
                self.backgroundContext.delete(result)
            }
        }
    }

    func collectionPublisher(userId: String) -> AnyPublisher<[Collection], Error> {
        let fetchRequest = CollectionData.fetchByUserIdRequest(userId: userId)
        // A sort descriptor is needed by `NSFetchedResultsController`.
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CollectionData.id, ascending: true)]
        return FetchedResultsPublisher(
            context: persistentContainer.viewContext,
            request: fetchRequest
        )
        .tryMap { try $0.map(Collection.init) }
        .eraseToAnyPublisher()
    }

    func replaceCollections(_ collections: [Collection], userId: String) async throws {
        let deleteRequest = CollectionData.deleteByUserIdRequest(userId: userId)
        let insertRequest = CollectionData.batchInsertRequest(objects: collections, userId: userId)
        try await executeBatchReplace(
            deleteRequest: deleteRequest,
            insertRequest: insertRequest
        )
    }

    func upsertCollection(_ collection: Collection, userId: String) async throws {
        try await backgroundContext.performAndSave {
            _ = CollectionData(context: self.backgroundContext, userId: userId, collection: collection)
        }
    }
}
