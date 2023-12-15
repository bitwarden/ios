import BitwardenSdk
import Combine

// MARK: - FolderService

/// A protocol for a `FolderService` which manages syncing and updates to the user's folders.
///
protocol FolderService {
    /// Add a new folder for the user, both to the backend and to local storage.
    ///
    /// - Parameter name: The name of the new folder.
    ///
    func addFolderWithServer(name: String) async throws

    /// Replaces the persisted list of folders for the user.
    ///
    /// - Parameters:
    ///   - folders: The updated list of folders for the user.
    ///   - userId: The user ID associated with the folders.
    ///
    func replaceFolders(_ folders: [FolderResponseModel], userId: String) async throws

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
        stateService: StateService
    ) {
        self.folderAPIService = folderAPIService
        self.folderDataStore = folderDataStore
        self.stateService = stateService
    }
}

extension DefaultFolderService {
    func addFolderWithServer(name: String) async throws {
        let userID = try await stateService.getActiveAccountId()

        // Add the folder to the backend.
        let response = try await folderAPIService.addFolder(name: name)

        // Add the folder to the local data store.
        try await folderDataStore.upsertFolder(Folder(folderResponseModel: response), userId: userID)
    }

    func replaceFolders(_ folders: [FolderResponseModel], userId: String) async throws {
        try await folderDataStore.replaceFolders(folders.map(Folder.init), userId: userId)
    }

    func foldersPublisher() async throws -> AnyPublisher<[Folder], Error> {
        let userID = try await stateService.getActiveAccountId()
        return folderDataStore.folderPublisher(userId: userID)
    }
}
