import BitwardenSdk
import Combine
import CoreData

// MARK: - CipherDataStore

/// A protocol for a data store that handles performing data requests for ciphers.
///
protocol CipherDataStore: AnyObject {
    /// Deletes all `Cipher` objects for a specific user.
    ///
    /// - Parameter userId: The user ID of the user associated with the objects to delete.
    ///
    func deleteAllCiphers(userId: String) async throws

    /// Deletes a `Cipher` by ID for a user.
    ///
    /// - Parameters:
    ///   - id: The ID of the `Cipher` to delete.
    ///   - userId: The user ID of the user associated with the object to delete.
    ///
    func deleteCipher(id: String, userId: String) async throws

    /// Attempt to fetch a cipher with the given id.
    ///
    /// - Parameter id: The id of the cipher to find.
    /// - Returns: The cipher if it was found and `nil` if not.
    ///
    func fetchCipher(withId id: String, userId: String) async -> Cipher?

    /// A publisher for a user's cipher objects.
    ///
    /// - Parameter userId: The user ID of the user to associated with the objects to fetch.
    /// - Returns: A publisher for the user's ciphers.
    ///
    func cipherPublisher(userId: String) -> AnyPublisher<[Cipher], Error>

    /// Replaces a list of `Cipher` objects for a user.
    ///
    /// - Parameters:
    ///   - ciphers: The list of ciphers to replace any existing ciphers.
    ///   - userId: The user ID of the user associated with the ciphers.
    ///
    func replaceCiphers(_ ciphers: [Cipher], userId: String) async throws

    /// Inserts or updates a cipher for a user.
    ///
    /// - Parameters:
    ///   - cipher: The cipher to insert or update.
    ///   - userId: The user ID of the user associated with the cipher.
    ///
    func upsertCipher(_ cipher: Cipher, userId: String) async throws
}

extension DataStore: CipherDataStore {
    func deleteAllCiphers(userId: String) async throws {
        try await executeBatchDelete(CipherData.deleteByUserIdRequest(userId: userId))
    }

    func deleteCipher(id: String, userId: String) async throws {
        try await backgroundContext.performAndSave {
            let results = try self.backgroundContext.fetch(CipherData.fetchByIdRequest(id: id, userId: userId))
            for result in results {
                self.backgroundContext.delete(result)
            }
        }
    }

    func fetchCipher(withId id: String, userId: String) async -> Cipher? {
        await backgroundContext.perform {
            try? self.backgroundContext.fetch(CipherData.fetchByIdRequest(id: id, userId: userId))
                .compactMap(Cipher.init)
                .first
        }
    }

    func cipherPublisher(userId: String) -> AnyPublisher<[Cipher], Error> {
        let fetchRequest = CipherData.fetchByUserIdRequest(userId: userId)
        // A sort descriptor is needed by `NSFetchedResultsController`.
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CipherData.id, ascending: true)]
        return FetchedResultsPublisher(
            context: persistentContainer.viewContext,
            request: fetchRequest
        )
        .tryMap { try $0.map(Cipher.init) }
        .eraseToAnyPublisher()
    }

    func replaceCiphers(_ ciphers: [Cipher], userId: String) async throws {
        let deleteRequest = CipherData.deleteByUserIdRequest(userId: userId)
        let insertRequest = try CipherData.batchInsertRequest(objects: ciphers, userId: userId)
        try await executeBatchReplace(
            deleteRequest: deleteRequest,
            insertRequest: insertRequest
        )
    }

    func upsertCipher(_ cipher: Cipher, userId: String) async throws {
        try await backgroundContext.performAndSave {
            _ = try CipherData(context: self.backgroundContext, userId: userId, cipher: cipher)
        }
    }
}
