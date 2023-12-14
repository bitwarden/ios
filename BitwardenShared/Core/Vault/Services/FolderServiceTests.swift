import BitwardenSdk
import XCTest

@testable import BitwardenShared

class FolderServiceTests: XCTestCase {
    // MARK: Properties

    var folderDataStore: MockFolderDataStore!
    var subject: FolderService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        folderDataStore = MockFolderDataStore()

        subject = DefaultFolderService(
            folderDataStore: folderDataStore,
            stateService: MockStateService()
        )
    }

    override func tearDown() {
        super.tearDown()

        folderDataStore = nil
        subject = nil
    }

    // MARK: Tests

    /// `replaceFolders(_:userId:)` replaces the persisted folders in the data store.
    func test_replaceFolders() async throws {
        let folders: [FolderResponseModel] = [
            FolderResponseModel(id: "1", name: "Folder 1", revisionDate: Date()),
            FolderResponseModel(id: "2", name: "Folder 2", revisionDate: Date()),
        ]

        try await subject.replaceFolders(folders, userId: "1")

        XCTAssertEqual(folderDataStore.replaceFoldersValue, folders.map(Folder.init))
        XCTAssertEqual(folderDataStore.replaceFoldersUserId, "1")
    }
}
