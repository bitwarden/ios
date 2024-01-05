import BitwardenSdk
import Combine
import Foundation

// MARK: - SyncService

/// A protocol for a service that manages syncing vault data with the API.
///
protocol SyncService: AnyObject {
    // MARK: Methods

    /// Clears any cached data in the service.
    ///
    func clearCachedData()

    /// Performs an API request to sync the user's vault data.
    ///
    func fetchSync() async throws

    /// A publisher for the sync response.
    ///
    /// - Returns: A publisher for the sync response.
    ///
    func syncResponsePublisher() -> AnyPublisher<SyncResponseModel?, Never>
}

// MARK: - DefaultSyncService

/// A default implementation of a `SyncService` which manages syncing vault data with the API.
///
class DefaultSyncService: SyncService {
    // MARK: Properties

    /// The service for managing the ciphers for the user.
    let cipherService: CipherService

    /// The service for managing the collections for the user.
    let collectionService: CollectionService

    /// The service for managing the folders for the user.
    let folderService: FolderService

    /// The service for managing the organizations for the user.
    let organizationService: OrganizationService

    /// The service for managing the sends for the user.
    let sendService: SendService

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// The API service used to perform sync API requests.
    let syncAPIService: SyncAPIService

    /// A subject containing the sync response.
    var syncResponseSubject = CurrentValueSubject<SyncResponseModel?, Never>(nil)

    // MARK: Initialization

    /// Initializes a `DefaultSyncService`.
    ///
    /// - Parameters:
    ///   - cipherService: The service for managing the ciphers for the user.
    ///   - collectionService: The service for managing the collections for the user.
    ///   - folderService: The service for managing the folders for the user.
    ///   - organizationService: The service for managing the organizations for the user.
    ///   - sendService: The service for managing the sends for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncAPIService: The API service used to perform sync API requests.
    ///
    init(
        cipherService: CipherService,
        collectionService: CollectionService,
        folderService: FolderService,
        organizationService: OrganizationService,
        sendService: SendService,
        stateService: StateService,
        syncAPIService: SyncAPIService
    ) {
        self.cipherService = cipherService
        self.collectionService = collectionService
        self.folderService = folderService
        self.organizationService = organizationService
        self.sendService = sendService
        self.stateService = stateService
        self.syncAPIService = syncAPIService
    }
}

extension DefaultSyncService {
    func clearCachedData() {
        syncResponseSubject.value = nil
    }

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

        syncResponseSubject.value = response

        try await stateService.setLastSyncTime(Date(), userId: userId)
    }

    func syncResponsePublisher() -> AnyPublisher<SyncResponseModel?, Never> {
        syncResponseSubject.eraseToAnyPublisher()
    }
}
