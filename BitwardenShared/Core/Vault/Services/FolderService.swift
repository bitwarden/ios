import BitwardenSdk
import Combine

// MARK: - FolderService

/// A protocol for a `FolderService` which manages syncing and updates to the user's folders.
///
protocol FolderService {
    /// Add a new folder for the current user, both in the backend and in local storage.
    ///
    /// - Parameter name: The name of the new folder.
    /// - Returns: The added folder.
    ///
    func addFolderWithServer(name: String) async throws -> Folder

    /// Delete a folder for the current user, both in the backend and in local storage.
    ///
    /// - Parameter id: The id of the folder to delete.
    ///
    func deleteFolderWithServer(id: String) async throws

    /// Delete a folder for the current user, in local storage.
    ///
    /// - Parameter id: The id of the folder to delete.
    ///
    func deleteFolderWithLocalStorage(id: String) async throws

    /// Edit a folder for the current user, both in the backend and in local storage.
    ///
    /// - Parameters:
    ///   - id: The id of the folder to edit.
    ///   - name: The new name of the folder.
    ///
    func editFolderWithServer(id: String, name: String) async throws

    /// Fetches the folders that are available to the user.
    ///
    /// - Returns: The folders that are available to the user.
    ///
    func fetchAllFolders() async throws -> [Folder]

    /// Fetches the folder with the provided `id`, if one exists in the local storage.
    ///
    /// - Parameter id: The id of the folder to fetch.
    /// - Returns: The `Folder` if one can be found, or `nil`.
    ///
    func fetchFolder(id: String) async throws -> Folder?

    /// Replaces the persisted list of folders for the user.
    ///
    /// - Parameters:
    ///   - folders: The updated list of folders for the user.
    ///   - userId: The user ID associated with the folders.
    ///
    func replaceFolders(_ folders: [FolderResponseModel], userId: String) async throws

    /// Attempts to synchronize a folder with the server.
    ///
    /// This method fetches the updated folder value from the server and updates the value in the
    /// local storage.
    ///
    /// - Parameter id: The id of the folder to fetch.
    ///
    func syncFolderWithServer(withId id: String) async throws

    // MARK: Publishers

    /// A publisher for the list of folders.
    ///
    /// - Returns: The list of encrypted folders.
    ///
    func foldersPublisher() async throws -> AnyPublisher<[Folder], Error>
}

// MARK: - DefaultFolderService

class DefaultFolderService: FolderService {
    // MARK: Properties

    /// The services used to make folder related API requests.
    let folderAPIService: FolderAPIService

    /// The data store for managing the persisted folders for the user.
    let folderDataStore: FolderDataStore

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultFolderService`.
    ///
    /// - Parameters:
    ///   - folderAPIService: The services used to make folder related API requests.
    ///   - folderDataStore: The data store for managing the persisted folders for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        folderAPIService: FolderAPIService,
        folderDataStore: FolderDataStore,
        stateService: StateService,
    ) {
        self.folderAPIService = folderAPIService
        self.folderDataStore = folderDataStore
        self.stateService = stateService
    }
}

extension DefaultFolderService {
    func addFolderWithServer(name: String) async throws -> Folder {
        let userID = try await stateService.getActiveAccountId()

        // Add the folder to the backend.
        let response = try await folderAPIService.addFolder(name: name)

        // Add the folder to the local data store.
        let folder = Folder(folderResponseModel: response)
        try await folderDataStore.upsertFolder(folder, userId: userID)
        return folder
    }

    func deleteFolderWithServer(id: String) async throws {
        let userID = try await stateService.getActiveAccountId()

        // Delete the folder in the backend.
        _ = try await folderAPIService.deleteFolder(withID: id)

        // Delete the folder in the local data store.
        try await folderDataStore.deleteFolder(id: id, userId: userID)
    }

    func deleteFolderWithLocalStorage(id: String) async throws {
        let userID = try await stateService.getActiveAccountId()
        try await folderDataStore.deleteFolder(id: id, userId: userID)
    }

    func editFolderWithServer(id: String, name: String) async throws {
        let userID = try await stateService.getActiveAccountId()

        // Edit the folder in the backend.
        let response = try await folderAPIService.editFolder(withID: id, name: name)

        // Edit the folder in the local data store.
        try await folderDataStore.upsertFolder(Folder(folderResponseModel: response), userId: userID)
    }

    func fetchAllFolders() async throws -> [Folder] {
        let userId = try await stateService.getActiveAccountId()
        return try await folderDataStore.fetchAllFolders(userId: userId)
    }

    func fetchFolder(id: String) async throws -> Folder? {
        let userId = try await stateService.getActiveAccountId()
        return try await folderDataStore.fetchFolder(id: id, userId: userId)
    }

    func replaceFolders(_ folders: [FolderResponseModel], userId: String) async throws {
        try await folderDataStore.replaceFolders(folders.map(Folder.init), userId: userId)
    }

    func syncFolderWithServer(withId id: String) async throws {
        let userId = try await stateService.getActiveAccountId()
        let response = try await folderAPIService.getFolder(withId: id)
        let folder = Folder(folderResponseModel: response)
        try await folderDataStore.upsertFolder(folder, userId: userId)
    }

    // MARK: Publishers

    func foldersPublisher() async throws -> AnyPublisher<[Folder], Error> {
        let userID = try await stateService.getActiveAccountId()
        return folderDataStore.folderPublisher(userId: userID)
    }
}
