import BitwardenSdk
import Combine

// MARK: - FolderService

/// A protocol for a `FolderService` which manages syncing and updates to the user's folders.
///
protocol FolderService {
    /// Replaces the persisted list of folders for the user.
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

    /// The data store for managing the persisted folders for the user.
    let folderDataStore: FolderDataStore

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultFolderService`.
    ///
    /// - Parameters:
    ///   - folderDataStore: The data store for managing the persisted folders for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(folderDataStore: FolderDataStore, stateService: StateService) {
        self.folderDataStore = folderDataStore
        self.stateService = stateService
    }
}

extension DefaultFolderService {
    func replaceFolders(_ folders: [FolderResponseModel], userId: String) async throws {
        try await folderDataStore.replaceFolders(folders.map(Folder.init), userId: userId)
    }

    func foldersPublisher() async throws -> AnyPublisher<[Folder], Error> {
        let userID = try await stateService.getActiveAccountId()
        return folderDataStore.folderPublisher(userId: userID)
    }
}
