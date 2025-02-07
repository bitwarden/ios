import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockFolderService: FolderService {
    var addedFolderName: String?
    var addFolderWithServerResult: Result<Folder, Error> = .success(Folder.fixture())

    var deletedFolderId: String?

    var deleteFolderWithLocalStorageId: String?
    var deleteFolderWithLocalStorageResult: Result<Void, Error> = .success(())

    var editedFolderName: String?

    var fetchAllFoldersResult: Result<[Folder], Error> = .success([])

    var fetchFolderId: String?
    var fetchFolderResult: Result<Folder?, Error> = .success(nil)

    var replaceFoldersFolders: [FolderResponseModel]?
    var replaceFoldersUserId: String?

    var syncFolderWithServerId: String?
    var syncFolderWithServerResult: Result<Void, Error> = .success(())

    var foldersSubject = CurrentValueSubject<[Folder], Error>([])

    func addFolderWithServer(name: String) async throws -> Folder {
        addedFolderName = name
        return try addFolderWithServerResult.get()
    }

    func deleteFolderWithServer(id: String) async throws {
        deletedFolderId = id
    }

    func deleteFolderWithLocalStorage(id: String) async throws {
        deleteFolderWithLocalStorageId = id
        return try deleteFolderWithLocalStorageResult.get()
    }

    func editFolderWithServer(id _: String, name: String) async throws {
        editedFolderName = name
    }

    func fetchFolder(id: String) async throws -> BitwardenSdk.Folder? {
        fetchFolderId = id
        return try fetchFolderResult.get()
    }

    func fetchAllFolders() async throws -> [Folder] {
        try fetchAllFoldersResult.get()
    }

    func replaceFolders(_ folders: [FolderResponseModel], userId: String) async throws {
        replaceFoldersFolders = folders
        replaceFoldersUserId = userId
    }

    func syncFolderWithServer(withId id: String) async throws {
        syncFolderWithServerId = id
        return try syncFolderWithServerResult.get()
    }

    func foldersPublisher() async throws -> AnyPublisher<[Folder], Error> {
        foldersSubject.eraseToAnyPublisher()
    }
}
