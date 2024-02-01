import BitwardenSdk
import XCTest

@testable import BitwardenShared

class FolderServiceTests: XCTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var folderAPIService: APIService!
    var folderDataStore: MockFolderDataStore!
    var stateService: MockStateService!
    var subject: FolderService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        folderAPIService = APIService(client: client)
        folderDataStore = MockFolderDataStore()
        stateService = MockStateService()

        subject = DefaultFolderService(
            folderAPIService: folderAPIService,
            folderDataStore: folderDataStore,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        folderAPIService = nil
        folderDataStore = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `addFolderWithServer(name:)` adds the new folder in both the backend and the data store.
    func test_addFolderWithServer() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        client.result = .httpSuccess(testData: .folderResponse)
        let folder = Folder(
            id: "123456789",
            name: "Something Clever",
            revisionDate: Date(year: 2023, month: 12, day: 25)
        )

        try await subject.addFolderWithServer(name: folder.name)

        XCTAssertEqual(folderDataStore.upsertFolderUserId, Account.fixtureAccountLogin().profile.userId)
        XCTAssertEqual(folderDataStore.upsertFolderValue, folder)
    }

    /// `deleteFolderWithServer(id:)` deletes the folder in both the backend and the data store.
    func test_deleteFolderWithServer() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        client.result = .httpSuccess(testData: APITestData(data: Data()))

        try await subject.deleteFolderWithServer(id: "123456789")

        XCTAssertEqual(folderDataStore.deleteFolderUserId, Account.fixtureAccountLogin().profile.userId)
        XCTAssertEqual(folderDataStore.deleteFolderId, "123456789")
    }

    /// `deleteFolderWithLocalStorage(id:)` deletes the folder in the data store.
    func test_deleteFolderWithLocalStorage() async throws {
        stateService.activeAccount = .fixture()

        try await subject.deleteFolderWithLocalStorage(id: "id")

        XCTAssertEqual(folderDataStore.deleteFolderUserId, "1")
        XCTAssertEqual(folderDataStore.deleteFolderId, "id")
    }

    /// `editFolderWithServer(id:name:)` edits the existing folder in both the backend and the data store.
    func test_editFolderWithServer() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        client.result = .httpSuccess(testData: .folderResponse)
        let folder = Folder(
            id: "123456789",
            name: "Something Clever",
            revisionDate: Date(year: 2023, month: 12, day: 25)
        )

        try await subject.editFolderWithServer(id: XCTUnwrap(folder.id), name: folder.name)

        XCTAssertEqual(folderDataStore.upsertFolderUserId, Account.fixtureAccountLogin().profile.userId)
        XCTAssertEqual(folderDataStore.upsertFolderValue, folder)
    }

    /// `fetchAllFolders` returns all folders.
    func test_fetchAllFolders() async throws {
        let folders: [Folder] = [
            .fixture(id: "1", name: "Folder 1"),
            .fixture(id: "2", name: "Folder 2"),
            .fixture(id: "3", name: "Folder 3"),
        ]

        folderDataStore.fetchAllFoldersResult = .success(folders)
        stateService.activeAccount = .fixture()

        let fetchedFolders = try await subject.fetchAllFolders()

        XCTAssertEqual(fetchedFolders, folders)
    }

    /// `fetchFolder(id:)` returns the folder.
    func test_fetchFolder() async throws {
        let folder = Folder.fixture(id: "1", name: "Folder 1")
        folderDataStore.fetchFolderResult = .success(folder)
        stateService.activeAccount = .fixture()

        let fetchedFolder = try await subject.fetchFolder(id: "1")

        XCTAssertEqual(fetchedFolder, folder)
    }

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

    /// `foldersPublisher()` returns a publisher that emits data as the data store changes.
    func test_foldersPublisher() async throws {
        stateService.activeAccount = .fixtureAccountLogin()

        var iterator = try await subject.foldersPublisher().values.makeAsyncIterator()
        _ = try await iterator.next()

        let folder = Folder.fixture()
        folderDataStore.folderSubject.value = [folder]
        let publisherValue = try await iterator.next()
        try XCTAssertNotNil(XCTUnwrap(publisherValue))
        try XCTAssertEqual(XCTUnwrap(publisherValue), [folder])
    }

    /// `syncFolderWithServer()` retrieves the folder from the backend and updates the data store.
    func test_syncFolderWithServer() async throws {
        stateService.activeAccount = .fixture()
        client.result = .httpSuccess(testData: .folderResponse)

        try await subject.syncFolderWithServer(withId: "123456789")

        XCTAssertEqual(folderDataStore.upsertFolderValue?.id, "123456789")
        XCTAssertEqual(folderDataStore.upsertFolderUserId, "1")
    }
}
