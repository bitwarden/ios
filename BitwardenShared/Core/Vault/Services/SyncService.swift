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
    /// - Parameter forceSync: Whether syncing should be forced, bypassing the account revision and
    ///     minimum sync interval checks.
    ///
    func fetchSync(forceSync: Bool) async throws
}

// MARK: - DefaultSyncService

/// A default implementation of a `SyncService` which manages syncing vault data with the API.
///
class DefaultSyncService: SyncService {
    // MARK: Properties

    /// The services used by the application to make account related API requests.
    private let accountAPIService: AccountAPIService

    /// The service for managing the ciphers for the user.
    private let cipherService: CipherService

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
    ///   - accountAPIService: The services used by the application to make account related API requests.
    ///   - cipherService: The service for managing the ciphers for the user.
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
        accountAPIService: AccountAPIService,
        cipherService: CipherService,
        collectionService: CollectionService,
        folderService: FolderService,
        organizationService: OrganizationService,
        policyService: PolicyService,
        sendService: SendService,
        settingsService: SettingsService,
        stateService: StateService,
        syncAPIService: SyncAPIService
    ) {
        self.accountAPIService = accountAPIService
        self.cipherService = cipherService
        self.collectionService = collectionService
        self.folderService = folderService
        self.organizationService = organizationService
        self.policyService = policyService
        self.sendService = sendService
        self.settingsService = settingsService
        self.stateService = stateService
        self.syncAPIService = syncAPIService
    }

    // MARK: Private

    /// Determine if a full sync is necessary.
    ///
    /// - Parameters:
    ///   - forceSync: Whether syncing should be forced, bypassing the account revision and minimum
    ///     sync interval checks.
    ///   - userId: The user ID of the account to sync.
    /// - Returns: Whether a sync should be performed.
    ///
    private func needsSync(forceSync: Bool, userId: String) async throws -> Bool {
        guard let lastSyncTime = try await stateService.getLastSyncTime(userId: userId), !forceSync else { return true }
        guard lastSyncTime.addingTimeInterval(Constants.minimumSyncInterval) < Date.now else { return false }

        do {
            guard let accountRevisionDate = try await accountAPIService.accountRevisionDate()
            else { return true }

            if lastSyncTime < accountRevisionDate {
                return true
            } else {
                // No updates to the account since the last sync. Update the last sync time but
                // don't do a full sync.
                try await stateService.setLastSyncTime(Date(), userId: userId)
                return false
            }
        } catch {
            return false
        }
    }
}

extension DefaultSyncService {
    func fetchSync(forceSync: Bool) async throws {
        let userId = try await stateService.getActiveAccountId()

        guard try await needsSync(forceSync: forceSync, userId: userId) else { return }

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
}
