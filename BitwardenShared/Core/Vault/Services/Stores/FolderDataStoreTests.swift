import BitwardenSdk
import CoreData
import XCTest

@testable import BitwardenShared

class FolderDataStoreTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DataStore!

    let folders = [
        Folder(id: "1", name: "FOLDER1", revisionDate: Date()),
        Folder(id: "2", name: "FOLDER2", revisionDate: Date()),
        Folder(id: "3", name: "FOLDER3", revisionDate: Date()),
    ]

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DataStore(errorReporter: MockErrorReporter(), storeType: .memory)
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `deleteAllFolders(user:)` removes all objects for the user.
    func test_deleteAllFolders() async throws {
        try await insertFolders(folders, userId: "1")
        try await insertFolders(folders, userId: "2")

        try await subject.deleteAllFolders(userId: "1")

        try XCTAssertTrue(fetchFolders(userId: "1").isEmpty)
        try XCTAssertEqual(fetchFolders(userId: "2").count, 3)
    }

    /// `deleteFolder(id:userId:)` removes the folder with the given ID for the user.
    func test_deleteFolder() async throws {
        try await insertFolders(folders, userId: "1")

        try await subject.deleteFolder(id: "2", userId: "1")

        try XCTAssertEqual(
            fetchFolders(userId: "1"),
            folders.filter { $0.id != "2" }
        )
    }

    /// `fetchAllFolders(userId:)` fetches all folders for a user.
    func test_fetchAllCollections() async throws {
        try await insertFolders(folders, userId: "1")

        let fetchedFolders = try await subject.fetchAllFolders(userId: "1")
        XCTAssertEqual(fetchedFolders, folders)

        let emptyFolders = try await subject.fetchAllFolders(userId: "-1")
        XCTAssertEqual(emptyFolders, [])
    }

    /// `folderPublisher(userId:)` returns a publisher for a user's folder objects.
    func test_folderPublisher() async throws {
        var publishedValues = [[Folder]]()
        let publisher = subject.folderPublisher(userId: "1")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { values in
                    publishedValues.append(values)
                }
            )
        defer { publisher.cancel() }

        try await subject.replaceFolders(folders, userId: "1")

        waitFor { publishedValues.count == 2 }
        XCTAssertTrue(publishedValues[0].isEmpty)
        XCTAssertEqual(publishedValues[1], folders)
    }

    /// `replaceFolders(_:userId)` replaces the list of folders for the user.
    func test_replaceFolders() async throws {
        try await insertFolders(folders, userId: "1")

        let newFolders = [
            Folder(id: "3", name: "FOLDER3", revisionDate: Date()),
            Folder(id: "4", name: "FOLDER4", revisionDate: Date()),
            Folder(id: "5", name: "FOLDER5", revisionDate: Date()),
        ]
        try await subject.replaceFolders(newFolders, userId: "1")

        XCTAssertEqual(try fetchFolders(userId: "1"), newFolders)
    }

    /// `upsertFolder(_:userId:)` inserts a folder for a user.
    func test_upsertFolder_insert() async throws {
        let folder = Folder(id: "1", name: "FOLDER1", revisionDate: Date())
        try await subject.upsertFolder(folder, userId: "1")

        try XCTAssertEqual(fetchFolders(userId: "1"), [folder])

        let folder2 = Folder(id: "2", name: "FOLDER2", revisionDate: Date())
        try await subject.upsertFolder(folder2, userId: "1")

        try XCTAssertEqual(fetchFolders(userId: "1"), [folder, folder2])
    }

    /// `upsertFolder(_:userId:)` updates an existing folder for a user.
    func test_upsertFolder_update() async throws {
        try await insertFolders(folders, userId: "1")

        let updatedFolder = Folder(id: "2", name: "UPDATED FOLDER2", revisionDate: Date())
        try await subject.upsertFolder(updatedFolder, userId: "1")

        var expectedFolders = folders
        expectedFolders[1] = updatedFolder

        try XCTAssertEqual(fetchFolders(userId: "1"), expectedFolders)
    }

    // MARK: Test Helpers

    /// A test helper to fetch all folder's for a user.
    private func fetchFolders(userId: String) throws -> [Folder] {
        let fetchRequest = FolderData.fetchByUserIdRequest(userId: userId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \FolderData.id, ascending: true)]
        return try subject.backgroundContext.fetch(fetchRequest).map(Folder.init)
    }

    /// A test helper for inserting a list of folders for a user.
    private func insertFolders(_ folders: [Folder], userId: String) async throws {
        try await subject.backgroundContext.performAndSave {
            for folder in folders {
                _ = FolderData(context: self.subject.backgroundContext, userId: userId, folder: folder)
            }
        }
    }
}
