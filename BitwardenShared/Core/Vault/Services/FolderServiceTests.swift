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

        try await subject.addFolderWithServer(name: "Something Clever")

        XCTAssertEqual(folderDataStore.upsertFolderUserId, Account.fixtureAccountLogin().profile.userId)
        XCTAssertEqual(folderDataStore.upsertFolderValue, folder)
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
}
