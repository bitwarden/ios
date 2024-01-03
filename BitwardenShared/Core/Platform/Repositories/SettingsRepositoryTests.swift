import BitwardenSdk
import XCTest

@testable import BitwardenShared

class SettingsRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var clientVault: MockClientVaultService!
    var folderService: MockFolderService!
    var pasteboardService: MockPasteboardService!
    var stateService: MockStateService!
    var subject: DefaultSettingsRepository!
    var syncService: MockSyncService!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientVault = MockClientVaultService()
        folderService = MockFolderService()
        pasteboardService = MockPasteboardService()
        stateService = MockStateService()
        syncService = MockSyncService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultSettingsRepository(
            clientVault: clientVault,
            folderService: folderService,
            pasteboardService: pasteboardService,
            stateService: stateService,
            syncService: syncService,
            vaultTimeoutService: vaultTimeoutService
        )
    }

    override func tearDown() {
        super.tearDown()

        clientVault = nil
        folderService = nil
        pasteboardService = nil
        stateService = nil
        subject = nil
        syncService = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `addFolder(name:)` encrypts the folder name and makes the request to add the folder.
    func test_addFolder() async throws {
        let folderName = "Test folder name"
        try await subject.addFolder(name: folderName)
        XCTAssertEqual(clientVault.clientFolders.encryptedFolders.first?.name, folderName)
        XCTAssertEqual(folderService.addedFolderName, folderName)
    }

    /// `clearClipboardValue` gets and sets the value from the `PasteboardService`.
    func test_clearClipboardValue() {
        pasteboardService.clearClipboardValue = .tenSeconds
        XCTAssertEqual(subject.clearClipboardValue, .tenSeconds)

        subject.clearClipboardValue = .twentySeconds
        XCTAssertEqual(pasteboardService.clearClipboardValue, .twentySeconds)
    }

    /// `deleteFolder(id:)` makes the request to delete the folder.
    func test_deleteFolder() async throws {
        try await subject.deleteFolder(id: "123456789")
        XCTAssertEqual(folderService.deletedFolderId, "123456789")
    }

    /// `editFolder(id:name:)` encrypts the folder name and makes the request to edit the folder.
    func test_editFolder() async throws {
        let folderName = "Test folder name"
        try await subject.editFolder(withID: "123456789", name: folderName)
        XCTAssertEqual(clientVault.clientFolders.encryptedFolders.first?.name, folderName)
        XCTAssertEqual(folderService.editedFolderName, folderName)
    }

    /// `fetchSync()` has the sync service perform a new sync.
    func test_fetchSync() async throws {
        try await subject.fetchSync()
        XCTAssertTrue(syncService.didFetchSync)
    }

    /// `getAllowSyncOnRefresh()` returns the expected value.
    func test_getAllowSyncOnRefresh() async throws {
        stateService.activeAccount = .fixture()

        // Defaults to false if no value is set.
        var value = try await subject.getAllowSyncOnRefresh()
        XCTAssertFalse(value)

        stateService.allowSyncOnRefresh["1"] = true
        value = try await subject.getAllowSyncOnRefresh()
        XCTAssertTrue(value)
    }

    /// `fetchSync()` throws an error if syncing fails.
    func test_fetchSync_error() async throws {
        struct SyncError: Error, Equatable {}
        syncService.fetchSyncResult = .failure(SyncError())

        await assertAsyncThrows(error: SyncError()) {
            try await subject.fetchSync()
        }
    }

    /// `foldersListPublisher()` returns a decrypted flow of the user's folders.
    func test_foldersListPublisher_emitsDecryptedList() async throws {
        // Prepare the publisher.
        var iterator = try await subject.foldersListPublisher().makeAsyncIterator()
        _ = try await iterator.next()

        // Prepare the sample data.
        let date = Date(year: 2023, month: 12, day: 25)
        let folder = Folder.fixture(revisionDate: date)
        let folderView = FolderView.fixture(revisionDate: date)

        // Ensure the list of folders is updated as expected.
        folderService.foldersSubject.value = [folder]
        let publisherValue = try await iterator.next()
        try XCTAssertNotNil(XCTUnwrap(publisherValue))
        try XCTAssertEqual(XCTUnwrap(publisherValue), [folderView])

        // Ensure the folders were decrypted by the client vault.
        XCTAssertEqual(clientVault.clientFolders.decryptedFolders, [folder])
    }

    /// `lastSyncTimePublisher` returns a publisher of the user's last sync time.
    func test_lastSyncTimePublisher() async throws {
        var iterator = try await subject.lastSyncTimePublisher().makeAsyncIterator()
        let initialValue = await iterator.next()
        try XCTAssertNil(XCTUnwrap(initialValue))

        let initialDate = Date(year: 2023, month: 12, day: 1)
        stateService.lastSyncTimeSubject.value = initialDate
        var lastSyncTime = await iterator.next()
        try XCTAssertEqual(XCTUnwrap(lastSyncTime), initialDate)

        let updatedDate = Date(year: 2023, month: 12, day: 4)
        stateService.lastSyncTimeSubject.value = updatedDate
        lastSyncTime = await iterator.next()
        try XCTAssertEqual(XCTUnwrap(lastSyncTime), updatedDate)
    }

    /// `lockVault(userId:)` passes a user id to be locked.
    func test_lockVault_unknownUserId() {
        let task = Task {
            await subject.lockVault(userId: nil)
        }
        waitFor(!vaultTimeoutService.lockedIds.isEmpty)
        task.cancel()
        XCTAssertEqual(vaultTimeoutService.lockedIds, [nil])
    }

    /// `lockVault(userId:)` passes a user id to be locked.
    func test_lockVault_knownUserId() {
        let task = Task {
            await subject.lockVault(userId: "123")
        }
        waitFor(!vaultTimeoutService.lockedIds.isEmpty)
        task.cancel()
        XCTAssertEqual(vaultTimeoutService.lockedIds, ["123"])
    }

    /// `logout()` has the state service log the user out.
    func test_logout() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        try await subject.logout()

        XCTAssertEqual(stateService.accountsLoggedOut, ["1"])
    }

    /// `unlockVault(userId:)` passes a user id to be unlocked.
    func test_unlockVault_unknownUserId() {
        let task = Task {
            await subject.unlockVault(userId: nil)
        }
        waitFor(!vaultTimeoutService.unlockedIds.isEmpty)
        task.cancel()
        XCTAssertEqual(vaultTimeoutService.unlockedIds, [nil])
    }

    /// `unlockVault(userId:)` passes a user id to be unlocked.
    func test_unlockVault_knownUserId() {
        let task = Task {
            await subject.unlockVault(userId: "123")
        }
        waitFor(!vaultTimeoutService.unlockedIds.isEmpty)
        task.cancel()
        XCTAssertEqual(vaultTimeoutService.unlockedIds, ["123"])
    }

    /// `updateAllowSyncOnRefresh(_:)` updates the value in the app settings store.
    func test_updateAllowSyncOnRefresh() async throws {
        stateService.activeAccount = .fixture()

        // The value should start off with a default of false.
        var value = try await stateService.getAllowSyncOnRefresh()
        XCTAssertFalse(value)

        // Set the value and ensure it updates.
        try await subject.updateAllowSyncOnRefresh(true)
        value = try await stateService.getAllowSyncOnRefresh()
        XCTAssertTrue(value)
    }
}
