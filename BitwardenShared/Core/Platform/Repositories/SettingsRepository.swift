import BitwardenSdk
import Combine
import Foundation

/// A protocol for a `SettingsRepository` which manages access to the data needed by the UI layer.
///
protocol SettingsRepository: AnyObject {
    /// Get or set the clear clipboard raw value.
    var clearClipboardValue: ClearClipboardValue { get set }

    /// Add a new folder.
    ///
    /// - Parameter name: The name of the new folder.
    ///
    func addFolder(name: String) async throws

    /// Delete a folder.
    ///
    /// - Parameter id: The id of the folder to delete.
    ///
    func deleteFolder(id: String) async throws

    /// Edit an existing folder.
    ///
    /// - Parameters:
    ///   - id: The id of the folder to edit
    ///   - name: The new name of the folder.
    ///
    func editFolder(withID id: String, name: String) async throws

    /// Updates the user's vault by syncing it with the API.
    ///
    func fetchSync() async throws

    /// Get the current value of the allow sync on refresh value.
    func getAllowSyncOnRefresh() async throws -> Bool

    /// Get the current value of the connect to watch setting.
    func getConnectToWatch() async throws -> Bool

    /// Gets the default URI match type setting for the current user.
    ///
    func getDefaultUriMatchType() async throws -> UriMatchType

    /// Get the value of the disable auto-copy TOTP setting for the current user.
    ///
    func getDisableAutoTotpCopy() async throws -> Bool

    /// Get the current value of the sync to Authenticator setting.
    ///
    func getSyncToAuthenticator() async throws -> Bool

    /// A publisher for the last sync time.
    ///
    /// - Returns: A publisher for the last sync time.
    ///
    func lastSyncTimePublisher() async throws -> AsyncPublisher<AnyPublisher<Date?, Never>>

    /// Update the cached value of the sync on refresh setting.
    ///
    /// - Parameter allowSyncOnRefresh: Whether the vault should sync on refreshing.
    ///
    func updateAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool) async throws

    /// Update the cached value of the connect to watch setting.
    ///
    /// - Parameter connectToWatch: Whether to connect to the watch app.
    ///
    func updateConnectToWatch(_ connectToWatch: Bool) async throws

    /// Update the cached value of the default URI match type setting.
    ///
    /// - Parameter defaultUriMatchType: The default URI match type.
    ///
    func updateDefaultUriMatchType(_ defaultUriMatchType: UriMatchType) async throws

    /// Update the cached value of the disable auto-copy TOTP setting.
    ///
    /// - Parameter disableAutoTotpCopy: Whether a cipher's TOTP should be auto-copied during autofill.
    ///
    func updateDisableAutoTotpCopy(_ disableAutoTotpCopy: Bool) async throws

    /// Update the cached value of the sync to authenticator setting.
    ///
    /// - Parameter syncToAuthenticator: Whether to sync TOTP codes to the Authenticator app.
    ///
    func updateSyncToAuthenticator(_ syncToAuthenticator: Bool) async throws

    // MARK: Publishers

    /// The publisher to keep track of the list of the user's current folders.
    func foldersListPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[FolderView], Error>>
}

// MARK: - DefaultSettingsRepository

/// A default implementation of a `SettingsRepository`.
///
class DefaultSettingsRepository {
    // MARK: Properties

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service used to manage syncing and updates to the user's folders.
    private let folderService: FolderService

    /// The service used to manage copy/pasting from the device's clipboard.
    private let pasteboardService: PasteboardService

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The service used to handle syncing vault data with the API.
    private let syncService: SyncService

    /// The service used to manage vault access.
    private let vaultTimeoutService: VaultTimeoutService

    // MARK: Initialization

    /// Initialize a `DefaultSettingsRepository`.
    ///
    /// - Parameters:
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - folderService: The service used to manage syncing and updates to the user's folders.
    ///   - pasteboardService: The service used to manage copy/pasting from the device's clipboard.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///   - vaultTimeoutService: The service used to manage vault access.
    ///
    init(
        clientService: ClientService,
        folderService: FolderService,
        pasteboardService: PasteboardService,
        stateService: StateService,
        syncService: SyncService,
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.clientService = clientService
        self.folderService = folderService
        self.pasteboardService = pasteboardService
        self.stateService = stateService
        self.syncService = syncService
        self.vaultTimeoutService = vaultTimeoutService
    }
}

// MARK: - SettingsRepository

extension DefaultSettingsRepository: SettingsRepository {
    var clearClipboardValue: ClearClipboardValue {
        get { pasteboardService.clearClipboardValue }
        set { pasteboardService.updateClearClipboardValue(newValue) }
    }

    func addFolder(name: String) async throws {
        let folderView = FolderView(id: nil, name: name, revisionDate: Date.now)
        let folder = try await clientService.vault().folders().encrypt(folder: folderView)
        try await folderService.addFolderWithServer(name: folder.name)
    }

    func deleteFolder(id: String) async throws {
        try await folderService.deleteFolderWithServer(id: id)
    }

    func editFolder(withID id: String, name: String) async throws {
        // Encrypt the folder then save the new data.
        let folderView = FolderView(id: id, name: name, revisionDate: Date.now)
        let folder = try await clientService.vault().folders().encrypt(folder: folderView)
        try await folderService.editFolderWithServer(id: id, name: folder.name)
    }

    func fetchSync() async throws {
        try await syncService.fetchSync(forceSync: true)
    }

    func getAllowSyncOnRefresh() async throws -> Bool {
        try await stateService.getAllowSyncOnRefresh()
    }

    func getConnectToWatch() async throws -> Bool {
        try await stateService.getConnectToWatch()
    }

    func getDefaultUriMatchType() async throws -> UriMatchType {
        try await stateService.getDefaultUriMatchType()
    }

    func getDisableAutoTotpCopy() async throws -> Bool {
        try await stateService.getDisableAutoTotpCopy()
    }

    func getSyncToAuthenticator() async throws -> Bool {
        try await stateService.getSyncToAuthenticator()
    }

    func lastSyncTimePublisher() async throws -> AsyncPublisher<AnyPublisher<Date?, Never>> {
        try await stateService.lastSyncTimePublisher().values
    }

    func updateAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool) async throws {
        try await stateService.setAllowSyncOnRefresh(allowSyncOnRefresh)
    }

    func updateConnectToWatch(_ connectToWatch: Bool) async throws {
        try await stateService.setConnectToWatch(connectToWatch)
    }

    func updateDefaultUriMatchType(_ defaultUriMatchType: UriMatchType) async throws {
        try await stateService.setDefaultUriMatchType(defaultUriMatchType)
    }

    func updateDisableAutoTotpCopy(_ disableAutoTotpCopy: Bool) async throws {
        try await stateService.setDisableAutoTotpCopy(disableAutoTotpCopy)
    }

    func updateSyncToAuthenticator(_ syncToAuthenticator: Bool) async throws {
        try await stateService.setSyncToAuthenticator(syncToAuthenticator)
    }

    // MARK: Publishers

    func foldersListPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[FolderView], Error>> {
        try await folderService.foldersPublisher()
            .asyncTryMap { folders in
                try await self.clientService.vault().folders().decryptList(folders: folders)
            }
            .eraseToAnyPublisher()
            .values
    }
}
