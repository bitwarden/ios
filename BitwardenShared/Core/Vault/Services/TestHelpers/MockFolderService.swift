import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockFolderService: FolderService {
    var addedFolderName: String?
    var deletedFolderId: String?
    var editedFolderName: String?
    var fetchAllFoldersResult: Result<[Folder], Error> = .success([])
    var replaceFoldersFolders: [FolderResponseModel]?
    var replaceFoldersUserId: String?

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

    func fetchAllFolders() async throws -> [Folder] {
        try fetchAllFoldersResult.get()
    }

    func replaceFolders(_ folders: [FolderResponseModel], userId: String) async throws {
        replaceFoldersFolders = folders
        replaceFoldersUserId = userId
    }

    func foldersPublisher() async throws -> AnyPublisher<[Folder], Error> {
        foldersSubject.eraseToAnyPublisher()
    }
}
