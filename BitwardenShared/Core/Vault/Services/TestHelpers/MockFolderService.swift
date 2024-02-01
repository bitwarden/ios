import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockFolderService: FolderService {
    var addedFolderName: String?

    var deletedFolderId: String?

    var editedFolderName: String?

    var fetchAllFoldersResult: Result<[Folder], Error> = .success([])

    var fetchFolderId: String?
    var fetchFolderResult: Result<Folder?, Error> = .success(nil)

    var replaceFoldersFolders: [FolderResponseModel]?
    var replaceFoldersUserId: String?

    var syncFolderWithServerId: String?
    var syncFolderWithServerResult: Result<Void, Error> = .success(())

    var foldersSubject = CurrentValueSubject<[Folder], Error>([])

    func addFolderWithServer(name: String) async throws {
        addedFolderName = name
    }

    func deleteFolderWithServer(id: String) async throws {
        deletedFolderId = id
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
