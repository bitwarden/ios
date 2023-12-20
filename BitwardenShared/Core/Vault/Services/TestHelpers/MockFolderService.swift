import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockFolderService: FolderService {
    var replaceFoldersFolders: [FolderResponseModel]?
    var replaceFoldersUserId: String?

    var foldersSubject = CurrentValueSubject<[Folder], Error>([])

    func replaceFolders(_ folders: [FolderResponseModel], userId: String) async throws {
        replaceFoldersFolders = folders
        replaceFoldersUserId = userId
    }

    func foldersPublisher() async throws -> AnyPublisher<[Folder], Error> {
        foldersSubject.eraseToAnyPublisher()
    }
}
