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
}

// MARK: - DefaultSyncService

/// A default implementation of a `SyncService` which manages syncing vault data with the API.
///
class DefaultSyncService: SyncService {
    // MARK: Properties

    /// The service for managing the ciphers for the user.
    private let cipherService: CipherService

    /// The service for managing the collections for the user.
    private let collectionService: CollectionService

    /// The service for managing the folders for the user.
    private let folderService: FolderService

    /// The service for managing the organizations for the user.
    private let organizationService: OrganizationService

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
    ///   - collectionService: The service for managing the collections for the user.
    ///   - folderService: The service for managing the folders for the user.
    ///   - organizationService: The service for managing the organizations for the user.
    ///   - sendService: The service for managing the sends for the user.
    ///   - settingsService: The service for managing the organizations for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncAPIService: The API service used to perform sync API requests.
    ///
    init(
        cipherService: CipherService,
        collectionService: CollectionService,
        folderService: FolderService,
        organizationService: OrganizationService,
        sendService: SendService,
        settingsService: SettingsService,
        stateService: StateService,
        syncAPIService: SyncAPIService
    ) {
        self.cipherService = cipherService
        self.collectionService = collectionService
        self.folderService = folderService
        self.organizationService = organizationService
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

        try await cipherService.replaceCiphers(response.ciphers, userId: userId)
        try await collectionService.replaceCollections(response.collections, userId: userId)
        try await folderService.replaceFolders(response.folders, userId: userId)
        try await sendService.replaceSends(response.sends, userId: userId)
        try await settingsService.replaceEquivalentDomains(response.domains, userId: userId)

        try await stateService.setLastSyncTime(Date(), userId: userId)
    }
}
