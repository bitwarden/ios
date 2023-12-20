import BitwardenSdk
import Combine
import CoreData

// MARK: - FolderDataStore

/// A protocol for a data store that handles performing data requests for folders.
///
protocol FolderDataStore: AnyObject {
    /// Deletes all `Folder` objects for a specific user.
    ///
    /// - Parameter userId: The user ID of the user associated with the objects to delete.
    ///
    func deleteAllFolders(userId: String) async throws

    /// Deletes a `Folder` by ID for a user.
    ///
    /// - Parameters:
    ///   - id: The ID of the `Folder` to delete.
    ///   - userId: The user ID of the user associated with the object to delete.
    ///
    func deleteFolder(id: String, userId: String) async throws

    /// A publisher for a user's folder objects.
    ///
    /// - Parameter userId: The user ID of the user to associated with the objects to fetch.
    /// - Returns: A publisher for the user's folders.
    ///
    func folderPublisher(userId: String) -> AnyPublisher<[Folder], Error>

    /// Replaces a list of `Folder` objects for a user.
    ///
    /// - Parameters:
    ///   - folders: The list of folders to replace any existing folders.
    ///   - userId: The user ID of the user associated with the folders.
    ///
    func replaceFolders(_ folders: [Folder], userId: String) async throws

    /// Inserts or updates a folder for a user.
    ///
    /// - Parameters:
    ///   - folder: The folder to insert or update.
    ///   - userId: The user ID of the user associated with the folder.
    ///
    func upsertFolder(_ folder: Folder, userId: String) async throws
}

extension DataStore: FolderDataStore {
    func deleteAllFolders(userId: String) async throws {
        try await executeBatchDelete(FolderData.deleteByUserIdRequest(userId: userId))
    }

    func deleteFolder(id: String, userId: String) async throws {
        try await backgroundContext.performAndSave {
            let results = try self.backgroundContext.fetch(FolderData.fetchByIdRequest(id: id, userId: userId))
            for result in results {
                self.backgroundContext.delete(result)
            }
        }
    }

    func folderPublisher(userId: String) -> AnyPublisher<[Folder], Error> {
        let fetchRequest = FolderData.fetchByUserIdRequest(userId: userId)
        // A sort descriptor is needed by `NSFetchedResultsController`.
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \FolderData.id, ascending: true)]
        return FetchedResultsPublisher(
            context: persistentContainer.viewContext,
            request: fetchRequest
        )
        .tryMap { try $0.map(Folder.init) }
        .eraseToAnyPublisher()
    }

    func replaceFolders(_ folders: [Folder], userId: String) async throws {
        let deleteRequest = FolderData.deleteByUserIdRequest(userId: userId)
        let insertRequest = try FolderData.batchInsertRequest(folders: folders, userId: userId)
        try await executeBatchReplace(
            deleteRequest: deleteRequest,
            insertRequest: insertRequest
        )
    }

    func upsertFolder(_ folder: Folder, userId: String) async throws {
        try await backgroundContext.performAndSave {
            _ = FolderData(context: self.backgroundContext, userId: userId, folder: folder)
        }
    }
}
