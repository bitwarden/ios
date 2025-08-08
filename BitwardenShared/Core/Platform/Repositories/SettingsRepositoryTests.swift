import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

class SettingsRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var clientService: MockClientService!
    var folderService: MockFolderService!
    var pasteboardService: MockPasteboardService!
    var stateService: MockStateService!
    var subject: DefaultSettingsRepository!
    var syncService: MockSyncService!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientService = MockClientService()
        folderService = MockFolderService()
        pasteboardService = MockPasteboardService()
        stateService = MockStateService()
        syncService = MockSyncService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultSettingsRepository(
            clientService: clientService,
            folderService: folderService,
            pasteboardService: pasteboardService,
            stateService: stateService,
            syncService: syncService,
            vaultTimeoutService: vaultTimeoutService
        )
    }

    override func tearDown() {
        super.tearDown()

        clientService = nil
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
        let folder = Folder.fixture(name: folderName)
        folderService.addFolderWithServerResult = .success(folder)
        let folderView = FolderView(folder: folder)
        clientService.mockVault.clientFolders.decryptFolderResult = .success(folderView)

        let addedFolder = try await subject.addFolder(name: folderName)

        XCTAssertEqual(addedFolder, folderView)
        XCTAssertEqual(clientService.mockVault.clientFolders.encryptedFolders.count, 1)
        XCTAssertNil(clientService.mockVault.clientFolders.encryptedFolders.first?.id)
        XCTAssertEqual(clientService.mockVault.clientFolders.encryptedFolders.first?.name, folderName)
        XCTAssertEqual(clientService.mockVault.clientFolders.decryptFolderValueToDecrypt, folder)
        XCTAssertEqual(folderService.addedFolderName, folderName)
    }

    /// `addFolder(name:)` throws an error if it's unable to decrypt the folder returned from the server.
    func test_addFolder_errorDecrypt() async throws {
        clientService.mockVault.clientFolders.decryptFolderResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.addFolder(name: "Test folder")
        }
    }

    /// `addFolder(name:)` throws an error if the server returns an error.
    func test_addFolder_errorServer() async throws {
        folderService.addFolderWithServerResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.addFolder(name: "Test folder")
        }
    }

    /// `allowUniversalClipboard` gets and sets the value from the `PasteboardService`.
    func test_allowUniversalClipboard() {
        pasteboardService.allowUniversalClipboard = true
        XCTAssertTrue(subject.allowUniversalClipboard)

        subject.allowUniversalClipboard = false
        XCTAssertFalse(subject.allowUniversalClipboard)
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
        XCTAssertEqual(clientService.mockVault.clientFolders.encryptedFolders.first?.name, folderName)
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

    /// `getConnectToWatch()` returns the expected value.
    func test_getConnectToWatch() async throws {
        stateService.activeAccount = .fixture()

        // Defaults to false if no value is set.
        var value = try await subject.getConnectToWatch()
        XCTAssertFalse(value)

        stateService.connectToWatchByUserId["1"] = true
        value = try await subject.getConnectToWatch()
        XCTAssertTrue(value)
    }

    /// `getDefaultUriMatchType()` returns the default URI match type value.
    func test_getDefaultUriMatchType() async throws {
        stateService.activeAccount = .fixture()

        let initialValue = await subject.getDefaultUriMatchType()
        XCTAssertEqual(initialValue, .domain)

        stateService.defaultUriMatchTypeByUserId["1"] = .never
        let value = await subject.getDefaultUriMatchType()
        XCTAssertEqual(value, .never)
    }

    /// `getDisableAutoTotpCopy()` returns the disable auto-copy TOTP value.
    func test_getDisableAutoTotpCopy() async throws {
        stateService.activeAccount = .fixture()

        let initialValue = try await subject.getDisableAutoTotpCopy()
        XCTAssertFalse(initialValue)

        stateService.disableAutoTotpCopyByUserId["1"] = true
        let value = try await subject.getDisableAutoTotpCopy()
        XCTAssertTrue(value)
    }

    /// `getSiriAndShortcutsAccess()` returns the Siri & Shortcuts access value.
    func test_getSiriAndShortcutsAccess() async throws {
        stateService.activeAccount = .fixture()

        let initialValue = try await subject.getSiriAndShortcutsAccess()
        XCTAssertFalse(initialValue)

        stateService.siriAndShortcutsAccess["1"] = true
        let value = try await subject.getSiriAndShortcutsAccess()
        XCTAssertTrue(value)
    }

    /// `getSyncToAuthenticator()` returns the expected value.
    func test_getSyncToAuthenticator() async throws {
        stateService.activeAccount = .fixture()

        // Defaults to false if no value is set.
        var value = try await subject.getSyncToAuthenticator()
        XCTAssertFalse(value)

        stateService.syncToAuthenticatorByUserId["1"] = true
        value = try await subject.getSyncToAuthenticator()
        XCTAssertTrue(value)
    }

    /// `fetchSync()` throws an error if syncing fails.
    func test_fetchSync_error() async throws {
        syncService.fetchSyncResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.fetchSync()
        }
    }

    /// `foldersListPublisher()` returns a decrypted flow of the user's folders in ascending alphabetically order.
    func test_foldersListPublisher_emitsDecryptedList() async throws {
        // Prepare the publisher.
        var iterator = try await subject.foldersListPublisher().makeAsyncIterator()
        _ = try await iterator.next()

        // Prepare the sample data.
        let date = Date(year: 2023, month: 12, day: 25)
        let folder = Folder.fixture(name: "ZZ", revisionDate: date)
        let folderView = FolderView.fixture(name: "ZZ", revisionDate: date)

        let folder2 = Folder.fixture(name: "AA", revisionDate: date)
        let folderView2 = FolderView.fixture(name: "AA", revisionDate: date)

        // Ensure the list of folders is updated as expected.
        folderService.foldersSubject.value = [folder, folder2]
        let publisherValue = try await iterator.next()
        try XCTAssertNotNil(XCTUnwrap(publisherValue))
        try XCTAssertEqual(XCTUnwrap(publisherValue), [folderView2, folderView])

        // Ensure the folders were decrypted by the client vault.
        XCTAssertEqual(clientService.mockVault.clientFolders.decryptedFolders, [folder, folder2])
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

    /// `updateAllowSyncOnRefresh()` updates the value in the state service.
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

    /// `updateConnectToWatch()` updates the value in the state service.
    func test_updateConnectToWatch() async throws {
        stateService.activeAccount = .fixture()

        // The value should start off with a default of false.
        var value = try await stateService.getConnectToWatch()
        XCTAssertFalse(value)

        // Set the value and ensure it updates.
        try await subject.updateConnectToWatch(true)
        value = try await stateService.getConnectToWatch()
        XCTAssertTrue(value)
    }

    /// `updateDefaultUriMatchType(_:)` updates the state service's default URI match type value.
    func test_updateDefaultUriMatchType() async throws {
        stateService.activeAccount = .fixture()

        try await subject.updateDefaultUriMatchType(.exact)

        XCTAssertEqual(stateService.defaultUriMatchTypeByUserId["1"], .exact)
    }

    /// `updateDisableAutoTotpCopy(_:)` updates the state service's disable auto-copy TOTP value.
    func test_updateDisableAutoTotpCopy() async throws {
        stateService.activeAccount = .fixture()

        try await subject.updateDisableAutoTotpCopy(true)

        try XCTAssertTrue(XCTUnwrap(stateService.disableAutoTotpCopyByUserId["1"]))
    }

    /// `updateSiriAndShortcutsAccess(_:)` updates the state service's Siri & Shortcuts access value
    func test_updateSiriAndShortcutsAccess() async throws {
        stateService.activeAccount = .fixture()

        try await subject.updateSiriAndShortcutsAccess(true)

        try XCTAssertTrue(XCTUnwrap(stateService.siriAndShortcutsAccess["1"]))
    }

    /// `updateSyncToAuthenticator()` updates the value in the state service.
    func test_updateSyncToAuthenticator() async throws {
        stateService.activeAccount = .fixture()

        // The value should start off with a default of false.
        var value = try await stateService.getSyncToAuthenticator()
        XCTAssertFalse(value)

        // Set the value and ensure it updates.
        try await subject.updateSyncToAuthenticator(true)
        value = try await stateService.getSyncToAuthenticator()
        XCTAssertTrue(value)
    }
}
