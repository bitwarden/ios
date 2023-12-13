import BitwardenSdk
import Combine
import CoreData

/// A protocol for a data store that handles performing data requests for the generator.
///
protocol GeneratorDataStore: AnyObject {
    /// Deletes all `PasswordHistory` objects for a specific user.
    ///
    /// - Parameter userId: The user ID of the user associated with the objects to delete.
    ///
    func deleteAllPasswordHistory(userId: String) async throws

    /// Deletes any password history objects past the specified limit, keeping the most recent objects.
    ///
    /// - Parameters:
    ///   - userId: The user ID of the user associated with the objects to delete.
    ///   - limit: The maximum number of password history objects to allow for the user.
    ///
    func deletePasswordHistoryPastLimit(userId: String, limit: Int) async throws

    /// Fetches the most recent password history object for the specified user.
    ///
    /// - Parameter userId: The user ID of the user associated with the object to fetch.
    /// - Returns: The most recent password history object for the user.
    ///
    func fetchPasswordHistoryMostRecent(userId: String) async throws -> PasswordHistory?

    /// Inserts a new `PasswordHistory` object into the database for a specific user.
    ///
    /// - Parameters:
    ///   - userId: The user ID of the user that created the object.
    ///   - passwordHistory: The object to insert into the database.
    ///
    func insertPasswordHistory(userId: String, passwordHistory: PasswordHistory) async throws

    /// A publisher for a user's password history objects.
    ///
    /// - Parameter userId: The user ID of the user to associated with the objects to fetch.
    /// - Returns: A publisher for the user's password history.
    ///
    func passwordHistoryPublisher(userId: String) -> AnyPublisher<[PasswordHistory], Error>
}

extension DataStore: GeneratorDataStore {
    func deleteAllPasswordHistory(userId: String) async throws {
        try await backgroundContext.perform {
            try self.backgroundContext.executeAndMergeChanges(
                PasswordHistoryData.deleteByUserIdRequest(userId: userId),
                additionalContexts: [self.persistentContainer.viewContext]
            )
        }
    }

    func deletePasswordHistoryPastLimit(userId: String, limit: Int) async throws {
        try await backgroundContext.perform {
            let fetchRequest = PasswordHistoryData.fetchResultRequest()
            fetchRequest.sortDescriptors = [PasswordHistoryData.sortByLastUsedDateDescending]
            fetchRequest.fetchOffset = limit
            try self.backgroundContext.executeAndMergeChanges(
                NSBatchDeleteRequest(fetchRequest: fetchRequest),
                additionalContexts: [self.persistentContainer.viewContext]
            )
        }
    }

    func fetchPasswordHistoryMostRecent(userId: String) async throws -> PasswordHistory? {
        try await backgroundContext.perform {
            let fetchRequest = PasswordHistoryData.fetchByUserIdRequest(userId: userId)
            fetchRequest.fetchLimit = 1
            fetchRequest.sortDescriptors = [PasswordHistoryData.sortByLastUsedDateDescending]
            return try self.backgroundContext.fetch(fetchRequest)
                .map(PasswordHistory.init)
                .first
        }
    }

    func insertPasswordHistory(userId: String, passwordHistory: PasswordHistory) async throws {
        try await backgroundContext.perform {
            _ = PasswordHistoryData(
                context: self.backgroundContext,
                userId: userId,
                passwordHistory: passwordHistory
            )
            try self.backgroundContext.saveIfChanged()
        }
    }

    func passwordHistoryPublisher(userId: String) -> AnyPublisher<[PasswordHistory], Error> {
        let fetchRequest = PasswordHistoryData.fetchByUserIdRequest(userId: userId)
        fetchRequest.sortDescriptors = [
            PasswordHistoryData.sortByLastUsedDateDescending,
        ]
        return FetchedResultsPublisher(
            context: persistentContainer.viewContext,
            request: fetchRequest
        )
        .tryMap { try $0.map(PasswordHistory.init) }
        .eraseToAnyPublisher()
    }
}
