import BitwardenSdk
import Combine
import CoreData

// MARK: - SendDataStore

/// A protocol for a data store that handles performing data requests for sends.
///
protocol SendDataStore: AnyObject {
    /// Deletes all `Send` objects for a specific user.
    ///
    /// - Parameter userId: The user ID of the user associated with the objects to delete.
    ///
    func deleteAllSends(userId: String) async throws

    /// Deletes a `Send` by ID for a user.
    ///
    /// - Parameters:
    ///   - id: The ID of the `Send` to delete.
    ///   - userId: The user ID of the user associated with the object to delete.
    ///
    func deleteSend(id: String, userId: String) async throws

    /// Fetches a `Send` by id for a user.
    ///
    /// - Parameters:
    ///   - id: The id of the `Send` to fetch.
    ///   - userId: The id of the user associated with the send to retrieve.
    ///
    func fetchSend(id: String, userId: String) async throws ->Send?

    /// A publisher for a user's send objects.
    ///
    /// - Parameter userId: The user ID of the user to associated with the objects to fetch.
    /// - Returns: A publisher for the user's sends.
    ///
    func sendPublisher(userId: String) -> AnyPublisher<[Send], Error>

    /// Replaces a list of `Send` objects for a user.
    ///
    /// - Parameters:
    ///   - sends: The list of sends to replace any existing sends.
    ///   - userId: The user ID of the user associated with the sends.
    ///
    func replaceSends(_ sends: [Send], userId: String) async throws

    /// Inserts or updates a send for a user.
    ///
    /// - Parameters:
    ///   - send: The send to insert or update.
    ///   - userId: The user ID of the user associated with the send.
    ///
    func upsertSend(_ send: Send, userId: String) async throws
}

extension DataStore: SendDataStore {
    func deleteAllSends(userId: String) async throws {
        try await executeBatchDelete(SendData.deleteByUserIdRequest(userId: userId))
    }

    func deleteSend(id: String, userId: String) async throws {
        try await backgroundContext.performAndSave {
            let results = try self.backgroundContext.fetch(SendData.fetchByIdRequest(id: id, userId: userId))
            for result in results {
                self.backgroundContext.delete(result)
            }
        }
    }

    func fetchSend(id: String, userId: String) async throws -> Send? {
        try backgroundContext.fetch(SendData.fetchByIdRequest(id: id, userId: userId))
            .map(Send.init)
            .first
    }

    func sendPublisher(userId: String) -> AnyPublisher<[Send], Error> {
        let fetchRequest = SendData.fetchByUserIdRequest(userId: userId)
        // A sort descriptor is needed by `NSFetchedResultsController`.
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SendData.id, ascending: true)]
        return FetchedResultsPublisher(
            context: persistentContainer.viewContext,
            request: fetchRequest
        )
        .tryMap { try $0.map(Send.init) }
        .eraseToAnyPublisher()
    }

    func replaceSends(_ sends: [Send], userId: String) async throws {
        let deleteRequest = SendData.deleteByUserIdRequest(userId: userId)
        let insertRequest = try SendData.batchInsertRequest(objects: sends, userId: userId)
        try await executeBatchReplace(
            deleteRequest: deleteRequest,
            insertRequest: insertRequest
        )
    }

    func upsertSend(_ send: Send, userId: String) async throws {
        try await backgroundContext.performAndSave {
            _ = try SendData(context: self.backgroundContext, userId: userId, send: send)
        }
    }
}
