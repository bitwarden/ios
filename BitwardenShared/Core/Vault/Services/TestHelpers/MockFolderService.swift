@testable import BitwardenShared

class MockFolderService: FolderService {
    var replaceFoldersFolders: [FolderResponseModel]?
    var replaceFoldersUserId: String?

    func replaceFolders(_ folders: [FolderResponseModel], userId: String) async throws {
        replaceFoldersFolders = folders
        replaceFoldersUserId = userId
    }
}
