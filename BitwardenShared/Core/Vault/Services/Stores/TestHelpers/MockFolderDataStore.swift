import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockFolderDataStore: FolderDataStore {
    var deleteAllFoldersUserId: String?

    var deleteFolderId: String?
    var deleteFolderUserId: String?

    var fetchAllFoldersResult: Result<[Folder], Error> = .success([])

    var folderSubject = CurrentValueSubject<[Folder], Error>([])

    var replaceFoldersValue: [Folder]?
    var replaceFoldersUserId: String?

    var upsertFolderValue: Folder?
    var upsertFolderUserId: String?

    func deleteAllFolders(userId: String) async throws {
        deleteAllFoldersUserId = userId
    }

    func deleteFolder(id: String, userId: String) async throws {
        deleteFolderId = id
        deleteFolderUserId = userId
    }

    func fetchAllFolders(userId: String) async throws -> [Folder] {
        try fetchAllFoldersResult.get()
    }

    func folderPublisher(userId: String) -> AnyPublisher<[Folder], Error> {
        folderSubject.eraseToAnyPublisher()
    }

    func replaceFolders(_ folders: [Folder], userId: String) async throws {
        replaceFoldersValue = folders
        replaceFoldersUserId = userId
    }

    func upsertFolder(_ folder: Folder, userId: String) async throws {
        upsertFolderValue = folder
        upsertFolderUserId = userId
    }
}
