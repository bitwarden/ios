import BitwardenSdk
import Combine
import Foundation

// MARK: - SyncService

/// A protocol for a service that manages syncing vault data with the API.
///
protocol SyncService: AnyObject {
    // MARK: Properties

    /// A delegate of the `SyncService` that is notified if a user's security stamp changes.
    var delegate: SyncServiceDelegate? { get set }

    // MARK: Methods

    /// Performs an API request to sync the user's vault data.
    ///
    /// - Parameter forceSync: Whether syncing should be forced, bypassing the account revision and
    ///     minimum sync interval checks.
    func fetchSync(forceSync: Bool) async throws

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

    /// Does a given account need a sync?
    ///
    /// - Parameter userId: The user id of the account.
    /// - Returns: A bool indicating if the user needs a sync or not.
    ///
    func needsSync(for userId: String) async throws -> Bool
}

// MARK: - SyncServiceDelegate

/// A protocol for a delegate of a `SyncService` which is notified to handle actions that need to
/// be taken outside of the service layer.
///
protocol SyncServiceDelegate: AnyObject {
    /// The user needs to remove their master password so they can be migrated to use Key Connector.
    ///
    /// - Parameter organizationName: The organization's name that requires Key Connector.
    ///
    @MainActor
    func removeMasterPassword(organizationName: String)

    /// The user's security stamp changed.
    ///
    /// - Parameter userId: The user ID of the user who's security stamp changed.
    ///
    func securityStampChanged(userId: String) async

    /// The user's profile changed and needs to set password.
    ///
    /// - Parameter orgIdentifier: The organization Identifier the user belongs to.
    ///
    func setMasterPassword(orgIdentifier: String) async
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

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service for managing the collections for the user.
    private let collectionService: CollectionService

    /// The service for managing the folders for the user.
    private let folderService: FolderService

    /// The service used by the application to manage Key Connector.
    private let keyConnectorService: KeyConnectorService

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

    /// A delegate of the `SyncService` that is notified if a user's security stamp changes.
    weak var delegate: SyncServiceDelegate?

    /// The time provider for this service.
    private let timeProvider: TimeProvider

    // MARK: Initialization

    /// Initializes a `DefaultSyncService`.
    ///
    /// - Parameters:
    ///   - accountAPIService: The services used by the application to make account related API requests.
    ///   - cipherService: The service for managing the ciphers for the user.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - collectionService: The service for managing the collections for the user.
    ///   - folderService: The service for managing the folders for the user.
    ///   - keyConnectorService: The service used by the application to manage Key Connector.
    ///   - organizationService: The service for managing the organizations for the user.
    ///   - policyService: The service for managing the polices for the user.
    ///   - sendService: The service for managing the sends for the user.
    ///   - settingsService: The service for managing the organizations for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncAPIService: The API service used to perform sync API requests.
    ///   - timeProvider: The time provider for this service.
    ///
    init(
        accountAPIService: AccountAPIService,
        cipherService: CipherService,
        clientService: ClientService,
        collectionService: CollectionService,
        folderService: FolderService,
        keyConnectorService: KeyConnectorService,
        organizationService: OrganizationService,
        policyService: PolicyService,
        sendService: SendService,
        settingsService: SettingsService,
        stateService: StateService,
        syncAPIService: SyncAPIService,
        timeProvider: TimeProvider
    ) {
        self.accountAPIService = accountAPIService
        self.cipherService = cipherService
        self.clientService = clientService
        self.collectionService = collectionService
        self.folderService = folderService
        self.keyConnectorService = keyConnectorService
        self.organizationService = organizationService
        self.policyService = policyService
        self.sendService = sendService
        self.settingsService = settingsService
        self.stateService = stateService
        self.syncAPIService = syncAPIService
        self.timeProvider = timeProvider
    }

    /// Determine if a full sync is necessary.
    ///
    /// - Parameters:
    ///   - userId: The user ID of the account to sync.
    /// - Returns: Whether a sync should be performed.
    ///
    func needsSync(for userId: String) async throws -> Bool {
        try await needsSync(forceSync: false, userId: userId)
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
        guard lastSyncTime.addingTimeInterval(Constants.minimumSyncInterval)
            < timeProvider.presentTime else { return false }
        do {
            guard let accountRevisionDate = try await accountAPIService.accountRevisionDate()
            else { return true }

            if lastSyncTime < accountRevisionDate {
                return true
            } else {
                // No updates to the account since the last sync. Update the last sync time but
                // don't do a full sync.
                try await stateService.setLastSyncTime(
                    timeProvider.presentTime,
                    userId: userId
                )
                return false
            }
        } catch {
            return false
        }
    }
}

extension DefaultSyncService {
    func fetchSync(forceSync: Bool) async throws {
        let account = try await stateService.getActiveAccount()
        let userId = account.profile.userId

        guard try await needsSync(forceSync: forceSync, userId: userId) else { return }

        let response = try await syncAPIService.getSync()

        if let savedStamp = account.profile.stamp,
           let currentStamp = response.profile?.securityStamp,
           savedStamp != currentStamp {
            await delegate?.securityStampChanged(userId: userId)
            return
        }

        if let organizations = response.profile?.organizations {
            try await organizationService.initializeOrganizationCrypto(
                organizations: organizations.compactMap(Organization.init)
            )
            try await organizationService.replaceOrganizations(organizations, userId: userId)
            try await checkTdeUserNeedsToSetPassword(account, organizations)
        }

        if let profile = response.profile {
            await stateService.updateProfile(from: profile, userId: userId)
            try await stateService.setUsesKeyConnector(profile.usesKeyConnector, userId: userId)
        }

        try await cipherService.replaceCiphers(response.ciphers, userId: userId)
        try await collectionService.replaceCollections(response.collections, userId: userId)
        try await folderService.replaceFolders(response.folders, userId: userId)
        try await sendService.replaceSends(response.sends, userId: userId)
        try await settingsService.replaceEquivalentDomains(response.domains, userId: userId)
        try await policyService.replacePolicies(response.policies, userId: userId)
        try await stateService.setLastSyncTime(timeProvider.presentTime, userId: userId)
        try await checkVaultTimeoutPolicy()

        if try await keyConnectorService.userNeedsMigration(),
           let organization = try await keyConnectorService.getManagingOrganization() {
            await delegate?.removeMasterPassword(organizationName: organization.name)
        }
    }

    func deleteCipher(data: SyncCipherNotification) async throws {
        let userId = try await stateService.getActiveAccountId()
        guard userId == data.userId else { return }

        try await cipherService.deleteCipherWithLocalStorage(id: data.id)
    }

    func deleteFolder(data: SyncFolderNotification) async throws {
        let userId = try await stateService.getActiveAccountId()
        guard userId == data.userId else { return }

        try await folderService.deleteFolderWithLocalStorage(id: data.id)

        let updatedCiphers = try await cipherService.fetchAllCiphers()
            .filter { $0.folderId == data.id }
            .map { $0.update(folderId: nil) }

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

        // If the local data is more recent than the notification, skip the sync.
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

        // If the local data is more recent than the notification, skip the sync.
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

    // MARK: Private Methods

    /// Checks if the policy for a maximum vault timeout value is enabled.
    /// If it is, update the timeout values for the user.
    ///
    /// If the user's stored timeout value is greater than the policy's timeout value,
    /// update it to equal the policy's timeout value.
    ///
    /// Set the user's timeout action to equal the policy's regardless.
    ///
    private func checkVaultTimeoutPolicy() async throws {
        guard let timeoutPolicyValues = try await policyService.fetchTimeoutPolicyValues() else { return }

        let action = timeoutPolicyValues.action
        let value = timeoutPolicyValues.value

        let timeoutAction = try await stateService.getTimeoutAction()
        let timeoutValue = try await stateService.getVaultTimeout()

        // Only update the user's stored vault timeout value if
        // their stored timeout value is > the policy's timeout value.
        if timeoutValue.rawValue > value || timeoutValue.rawValue < 0 {
            try await stateService.setVaultTimeout(
                value: SessionTimeoutValue(rawValue: value)
            )
        }

        try await stateService.setTimeoutAction(action: action ?? timeoutAction)
    }

    /// Checks if TDE user needs to set a master password
    ///
    /// TDE users can only have one organization
    ///
    private func checkTdeUserNeedsToSetPassword(
        _ account: Account,
        _ organizations: [ProfileOrganizationResponseModel]
    ) async throws {
        if organizations.count == 1,
           organizations.contains(where: \.passwordRequired),
           let userOrgId = organizations.first?.identifier,
           account.profile.userDecryptionOptions?.trustedDeviceOption != nil,
           account.profile.userDecryptionOptions?.hasMasterPassword == false {
            await delegate?.setMasterPassword(orgIdentifier: userOrgId)
        }
    }
} // swiftlint:disable:this file_length
