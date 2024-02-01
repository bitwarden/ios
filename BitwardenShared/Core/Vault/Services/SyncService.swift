import BitwardenSdk
import Combine
import Foundation

// MARK: - SyncService

/// A protocol for a service that manages syncing vault data with the API.
///
protocol SyncService: AnyObject {
    // MARK: Methods

    /// Performs an API request to sync the user's vault data.
    ///
    func fetchSync() async throws

    /// Deletes the cipher specified in the notification data in local storage.
    ///
    /// - Parameter data: The notification data for the cipher delete action.
    ///
    func deleteCipher(data: SyncCipherNotification) async throws

    /// Deletes the folder specified in the notification data in local storage.
    ///
    /// - Parameter data: The notification data for the folder delete action.
    ///
    func deleteFolder(data: SyncFolderNotification) async throws

    /// Deletes the send specified in the notification data in local storage.
    ///
    /// - Parameter data: The notification data for the send delete action.
    ///
    func deleteSend(data: SyncSendNotification) async throws

    /// Synchronizes the cipher specified in the notification data with the server.
    ///
    /// - Parameter data: The notification data for the cipher sync action.
    ///
    func fetchUpsertSyncCipher(data: SyncCipherNotification) async throws

    /// Synchronizes the folder specified in the notification data with the server.
    ///
    /// - Parameter data: The notification data for the folder sync action.
    ///
    func fetchUpsertSyncFolder(data: SyncFolderNotification) async throws

    /// Synchronizes the send specified in the notification data with the server.
    ///
    /// - Parameter data: The notification data for the send sync action.
    ///
    func fetchUpsertSyncSend(data: SyncSendNotification) async throws
}

// MARK: - DefaultSyncService

/// A default implementation of a `SyncService` which manages syncing vault data with the API.
///
class DefaultSyncService: SyncService {
    // MARK: Properties

    /// The service for managing the ciphers for the user.
    private let cipherService: CipherService

    /// The client used by the application to handle vault encryption and decryption tasks.
    private let clientVault: ClientVaultService

    /// The service for managing the collections for the user.
    private let collectionService: CollectionService

    /// The service for managing the folders for the user.
    private let folderService: FolderService

    /// The service for managing the organizations for the user.
    private let organizationService: OrganizationService

    /// The service for managing the polices for the user.
    private let policyService: PolicyService

    /// The service for managing the sends for the user.
    private let sendService: SendService

    /// The service for managing the settings for the user.
    let settingsService: SettingsService

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The API service used to perform sync API requests.
    private let syncAPIService: SyncAPIService

    // MARK: Initialization

    /// Initializes a `DefaultSyncService`.
    ///
    /// - Parameters:
    ///   - cipherService: The service for managing the ciphers for the user.
    ///   - clientVault: The client used by the application to handle vault encryption and
    ///     decryption tasks.
    ///   - collectionService: The service for managing the collections for the user.
    ///   - folderService: The service for managing the folders for the user.
    ///   - organizationService: The service for managing the organizations for the user.
    ///   - policyService: The service for managing the polices for the user.
    ///   - sendService: The service for managing the sends for the user.
    ///   - settingsService: The service for managing the organizations for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncAPIService: The API service used to perform sync API requests.
    ///
    init(
        cipherService: CipherService,
        clientVault: ClientVaultService,
        collectionService: CollectionService,
        folderService: FolderService,
        organizationService: OrganizationService,
        policyService: PolicyService,
        sendService: SendService,
        settingsService: SettingsService,
        stateService: StateService,
        syncAPIService: SyncAPIService
    ) {
        self.cipherService = cipherService
        self.clientVault = clientVault
        self.collectionService = collectionService
        self.folderService = folderService
        self.organizationService = organizationService
        self.policyService = policyService
        self.sendService = sendService
        self.settingsService = settingsService
        self.stateService = stateService
        self.syncAPIService = syncAPIService
    }
}

extension DefaultSyncService {
    func fetchSync() async throws {
        let userId = try await stateService.getActiveAccountId()

        let response = try await syncAPIService.getSync()

        if let organizations = response.profile?.organizations {
            await organizationService.initializeOrganizationCrypto(
                organizations: organizations.compactMap(Organization.init)
            )
            try await organizationService.replaceOrganizations(organizations, userId: userId)
        }

        if let profile = response.profile {
            await stateService.updateProfile(from: profile, userId: userId)
        }

        try await cipherService.replaceCiphers(response.ciphers, userId: userId)
        try await collectionService.replaceCollections(response.collections, userId: userId)
        try await folderService.replaceFolders(response.folders, userId: userId)
        try await sendService.replaceSends(response.sends, userId: userId)
        try await settingsService.replaceEquivalentDomains(response.domains, userId: userId)
        try await policyService.replacePolicies(response.policies, userId: userId)

        try await stateService.setLastSyncTime(Date(), userId: userId)
    }

    func deleteCipher(data: SyncCipherNotification) async throws {
        let userId = try await stateService.getActiveAccountId()
        guard userId == data.userId else { return }

        try await cipherService.deleteCipherWithServer(id: data.id)
    }

    func deleteFolder(data: SyncFolderNotification) async throws {
        let userId = try await stateService.getActiveAccountId()
        guard userId == data.userId else { return }

        let updatedCiphers = try await cipherService.fetchAllCiphers()
            .asyncMap { try await clientVault.ciphers().decrypt(cipher: $0) }
            .map { $0.update(folderId: nil) }
            .asyncMap { try await clientVault.ciphers().encrypt(cipherView: $0) }

        for cipher in updatedCiphers {
            try await cipherService.updateCipherWithLocalStorage(cipher)
        }
    }

    func deleteSend(data: SyncSendNotification) async throws {
        let userId = try await stateService.getActiveAccountId()
        guard userId == data.userId else { return }

        try await sendService.deleteSendWithLocalStorage(id: data.id)
    }

    func fetchUpsertSyncCipher(data: SyncCipherNotification) async throws {
        let userId = try await stateService.getActiveAccountId()
        guard userId == data.userId else { return }

        // If the local data is more recent than the nofication, skip the sync.
        let localCipher = try await cipherService.fetchCipher(withId: data.id)
        if let localCipher, let revisionDate = data.revisionDate, localCipher.revisionDate >= revisionDate {
            return
        }

        if let collectionIds = data.collectionIds {
            let collectionsToUpdate = try await collectionService
                .fetchAllCollections(includeReadOnly: true)
                .filter { collection in
                    guard let id = collection.id else { return false }
                    return !collectionIds.contains(id)
                }
            if collectionsToUpdate.isEmpty {
                return
            }
        }

        do {
            try await cipherService.syncCipherWithServer(withId: data.id)
        } catch let error as URLError {
            if (error as NSError).code == 404 {
                // The cipher does not exist on the server, and should be removed from local
                // storage.
                try await cipherService.deleteCipherWithLocalStorage(id: data.id)
            }
        }
    }

    func fetchUpsertSyncFolder(data: SyncFolderNotification) async throws {
        let userId = try await stateService.getActiveAccountId()
        guard userId == data.userId else { return }

        // If the local data is more recent than the nofication, skip the sync.
        let localFolder = try await folderService.fetchFolder(id: data.id)
        if let localFolder, let revisionDate = data.revisionDate, localFolder.revisionDate >= revisionDate {
            return
        }

        do {
            try await folderService.syncFolderWithServer(withId: data.id)
        } catch let error as URLError {
            if (error as NSError).code == 404 {
                try await folderService.deleteFolderWithServer(id: data.id)
            }
        }
    }

    func fetchUpsertSyncSend(data: SyncSendNotification) async throws {
        let userId = try await stateService.getActiveAccountId()
        guard userId == data.userId else { return }

        // If the local data is more recent than the nofication, skip the sync.
        let localSend = try await sendService.fetchSend(id: data.id)
        if let localSend, let revisionDate = data.revisionDate, localSend.revisionDate >= revisionDate {
            return
        }

        do {
            try await sendService.syncSendWithServer(id: data.id)
        } catch let error as URLError {
            if (error as NSError).code == 404 {
                try await sendService.deleteSendWithLocalStorage(id: data.id)
            }
        }
    }
}
