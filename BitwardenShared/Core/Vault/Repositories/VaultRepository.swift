import BitwardenKit
import BitwardenResources
import BitwardenSdk
import Combine
import Foundation
import OSLog

/// A protocol for a `VaultRepository` which manages access to the data needed by the UI layer.
///
public protocol VaultRepository: AnyObject {
    // MARK: API Methods

    /// Performs an API request to sync the user's vault data. The publishers in the repository can
    /// be used to subscribe to the vault data, which are updated as a result of the request.
    ///
    /// - Parameters:
    ///   - forceSync: Whether the sync is forced.
    ///   - filter: The filter to apply to the vault.
    ///   - isPeriodic: Whether the sync is periodic to take into account the minimum interval.
    ///
    func fetchSync(forceSync: Bool, filter: VaultFilterType, isPeriodic: Bool) async throws

    // MARK: Data Methods

    /// Adds a cipher to the user's vault.
    ///
    /// - Parameter cipher: The cipher that the user is added.
    ///
    func addCipher(_ cipher: CipherView) async throws

    /// Archives a cipher.
    ///
    /// - Parameter cipher: The cipher that the user is archiving.
    ///
    func archiveCipher(_ cipher: CipherView) async throws

    /// Shares multiple ciphers with an organization.
    ///
    /// - Parameters:
    ///   - ciphers: The ciphers to share.
    ///   - newOrganizationId: The ID of the organization that the ciphers are moving to.
    ///   - newCollectionIds: The IDs of the collections to include the ciphers in.
    ///
    func bulkShareCiphers(
        _ ciphers: [CipherView],
        newOrganizationId: String,
        newCollectionIds: [String],
    ) async throws

    /// Whether the vault filter can be shown to the user. It might not be shown to the user if the
    /// policies are set up to disable personal vault ownership and only allow the user to be in a
    /// single organization.
    ///
    /// - Returns: `true` if the vault filter can be shown.
    ///
    func canShowVaultFilter() async -> Bool

    /// Removes any temporarily downloaded attachments.
    func clearTemporaryDownloads()

    /// Creates a `VaultListSection` for excluded credentials.
    /// - Parameter cipher: The cipher found in excluded credentials.
    /// - Returns: A `VaultListSection` with the excluded cipher found.
    func createAutofillListExcludedCredentialSection(from cipher: CipherView) async throws -> VaultListSection

    /// Delete an attachment from a cipher.
    ///
    /// - Parameters:
    ///   - attachmentId: The id of the attachment to delete.
    ///   - cipherId: The id of the cipher that owns the attachment.
    ///
    /// - Returns: The updated cipher view with one less attachment.
    ///
    func deleteAttachment(withId attachmentId: String, cipherId: String) async throws -> CipherView?

    /// Delete a cipher from the user's vault.
    ///
    /// - Parameter id: The cipher id that to be deleted.
    ///
    func deleteCipher(_ id: String) async throws

    /// Validates the user's active account has access to premium features.
    ///
    /// - Returns: Whether the active account has premium.
    ///
    func doesActiveAccountHavePremium() async -> Bool

    /// Download and decrypt an attachment and save the file to local storage on the device.
    ///
    /// - Parameters:
    ///   - attachment: The attachment to download.
    ///   - cipher: The cipher the attachment belongs to.
    ///
    /// - Returns: The url of the temporary location of downloaded and decrypted data on the user's device.
    ///
    func downloadAttachment(
        _ attachment: AttachmentView,
        cipher: CipherView,
    ) async throws -> URL?

    /// Attempt to fetch a cipher with the given id.
    ///
    /// - Parameter id: The id of the cipher to find.
    /// - Returns: The cipher if it was found and `nil` if not.
    ///
    func fetchCipher(withId id: String) async throws -> CipherView?

    /// Fetches the ownership options that the user can select from for a cipher.
    ///
    /// - Parameter includePersonal: Whether to include the user's personal vault in the list.
    /// - Returns: The list of ownership options for a cipher.
    ///
    func fetchCipherOwnershipOptions(includePersonal: Bool) async throws -> [CipherOwner]

    /// Fetches the collections that are available to the user.
    ///
    /// - Parameter includeReadOnly: Whether to include read-only collections.
    /// - Returns: The collections that are available to the user.
    ///
    func fetchCollections(includeReadOnly: Bool) async throws -> [CollectionView]

    /// Fetches the folder with the specified id.
    /// - Parameter id: The id of the folder to fetch.
    /// - Returns: The folder with such id or `nil` if not found.
    func fetchFolder(withId id: String) async throws -> FolderView?

    /// Fetches the folders that are available to the user.
    ///
    /// - Returns: The folders that are available to the user.
    ///
    func fetchFolders() async throws -> [FolderView]

    /// Fetches an organization with the specified id.
    /// - Parameter id: The id of the organization to fetch.
    /// - Returns: The organization with such id or `nil` if not found.
    func fetchOrganization(withId id: String) async throws -> Organization?

    /// Gets a list of item types for the current user can create.
    ///
    func getItemTypesUserCanCreate() async -> [CipherType]

    /// Get the value of the disable auto-copy TOTP setting for the current user.
    ///
    func getDisableAutoTotpCopy() async throws -> Bool

    /// Gets the TOTP of a cipher if it's allowed to be copied.
    /// - Parameter cipher: The cipher that has the TOTP.
    /// - Returns: The TOTP if the user/org has the necessary permissions for it to be copied.
    func getTOTPKeyIfAllowedToCopy(cipher: CipherView) async throws -> String?

    /// Returns whether the user's vault is empty.
    ///
    /// - Returns: Whether the user's vault is empty.
    ///
    func isVaultEmpty() async throws -> Bool

    /// Migrates the user's personal vault items to an organization's default collection.
    ///
    /// - Parameter organizationId: The ID of the organization to migrate items to.
    ///
    func migratePersonalVault(to organizationId: String) async throws

    /// Regenerates the TOTP code for a given key.
    ///
    /// - Parameter key: The key for a TOTP code.
    /// - Returns: An updated LoginTOTPState.
    ///
    func refreshTOTPCode(for key: TOTPKeyModel) async throws -> LoginTOTPState

    /// Regenerates the TOTP codes for a list of Vault Items.
    ///
    /// - Parameter items: The list of items that need updated TOTP codes.
    /// - Returns: An updated list of items with new TOTP codes.
    ///
    func refreshTOTPCodes(for items: [VaultListItem]) async throws -> [VaultListItem]

    /// Returns whether master password reprompt is required for a cipher.
    ///
    /// - Parameter id: The ID of the cipher to check if reprompt is required.
    /// - Returns: Whether master password reprompt is required for a cipher.
    ///
    func repromptRequiredForCipher(id: String) async throws -> Bool

    /// Restores a cipher from the trash.
    ///
    /// - Parameter cipher: The cipher that the user is restoring.
    ///
    func restoreCipher(_ cipher: CipherView) async throws

    /// Save an attachment to a cipher.
    ///
    /// - Parameters:
    ///   - cipherView: The cipher to add the attachment to.
    ///   - fileData: The attachment's data.
    ///   - fileName: The attachment's name.
    ///
    /// - Returns: The updated cipher with the new attachment added.
    ///
    func saveAttachment(cipherView: CipherView, fileData: Data, fileName: String) async throws -> CipherView

    /// Shares a cipher with an organization.
    ///
    /// - Parameters:
    ///   - cipher: The cipher to share.
    ///   - newOrganizationId: The ID of the organization that the cipher is moving to.
    ///   - newCollectionIds: The IDs of the collections to include the cipher in.
    ///
    func shareCipher(_ cipher: CipherView, newOrganizationId: String, newCollectionIds: [String]) async throws

    /// Soft delete a cipher from the user's vault.
    ///
    /// - Parameter cipher: The cipher that the user is soft deleting.
    ///
    func softDeleteCipher(_ cipher: CipherView) async throws

    /// Unarchives a cipher from the vault.
    ///
    /// - Parameter cipher: The cipher that the user is unarchiving.
    ///
    func unarchiveCipher(_ cipher: CipherView) async throws

    /// Updates a cipher in the user's vault.
    ///
    /// - Parameter cipher: The cipher that the user is updating.
    ///
    func updateCipher(_ cipherView: CipherView) async throws

    /// Updates the list of collections for a cipher in the user's vault.
    ///
    /// - Parameter cipher: The cipher that the user is updating.
    ///
    func updateCipherCollections(_ cipher: CipherView) async throws

    // MARK: Publishers

    /// A publisher for the details of a cipher in the vault.
    ///
    /// - Parameter id: The cipher identifier to be notified when the cipher is updated.
    /// - Returns: A publisher for the details of a cipher which will be notified as the details of
    ///     the cipher change.
    ///
    func cipherDetailsPublisher(
        id: String,
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<CipherView?, Error>>

    /// A publisher for the list of a user's ciphers.
    ///
    /// - Returns: A publisher for the list of a user's ciphers.
    ///
    func cipherPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[CipherListView], Error>>

    /// A publisher for the list of a user's ciphers that can be used for autofill matching a URI.
    ///
    /// - Parameters:
    ///   - availableFido2CredentialsPublisher: The publisher for available Fido2 credentials for Fido2 autofill list.
    ///   - mode: The mode in which the autofill list is presented.
    ///   - group: The vault list group to filter.
    ///   - rpID: The relying party identifier of the Fido2 request.
    ///   - uri: The URI used to filter ciphers that have a matching URI
    ///
    /// - Returns: The list of a user's ciphers that can be used for autofill.
    func ciphersAutofillPublisher(
        availableFido2CredentialsPublisher: AnyPublisher<[BitwardenSdk.CipherView]?, Error>,
        mode: AutofillListMode,
        group: VaultListGroup?,
        rpID: String?,
        uri: String?,
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>>

    /// Determine if a full sync is necessary.
    ///
    /// - Returns: Whether a sync should be performed.
    ///
    func needsSync() async throws -> Bool

    /// A publisher for the list of organizations the user is a member of.
    ///
    /// - Returns: A publisher for the list of organizations the user is a member of.
    ///
    func organizationsPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[Organization], Error>>

    /// A publisher for the vault list which returns a list of sections and items that are
    /// displayed in the vault.
    ///
    /// - Parameter filter: A filter to apply to the vault items.
    /// - Returns: A publisher for the sections of the vault list which will be notified as the
    ///     data changes.
    ///
    func vaultListPublisher(
        filter: VaultListFilter,
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>>

    /// A publisher for the vault search list which returns a list of sections and items that are
    /// displayed in the vault.
    ///
    /// - Parameters:
    ///   - mode: The `AutofillListMode` to choose the correct strategy, if any.
    ///   - filterPublisher: Filter publisher to be subscribed to changes to build the sections.
    /// - Returns: A publisher for the sections of the vault list which will be notified as the
    ///     data changes.
    ///
    func vaultSearchListPublisher(
        mode: AutofillListMode?,
        filterPublisher: AnyPublisher<VaultListFilter, Error>,
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>>
}

extension VaultRepository {
    /// Fetches a complete `CipherView` from the `CipherListView`.
    /// - Parameter cipherListView: The `CipherListView` to use to fetch the `CipherView`.
    /// - Returns: The `CipherView` corresponding to the `cipherListView` passed as parameter.
    func fetchCipher(from cipherListView: CipherListView) async throws -> CipherView {
        guard let cipherId = cipherListView.id,
              let cipherView = try await fetchCipher(withId: cipherId) else {
            throw BitwardenError.dataError("Cipher not found from CipherListView.")
        }
        return cipherView
    }
}

/// A default implementation of a `VaultRepository`.
///
class DefaultVaultRepository {
    // MARK: Properties

    /// The service used to manage syncing and updates to the user's ciphers.
    private let cipherService: CipherService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service to get server-specified configuration.
    private let configService: ConfigService

    /// The helper functions for collections.
    private let collectionHelper: CollectionHelper

    /// The service for managing the collections for the user.
    private let collectionService: CollectionService

    /// The service used by the application to manage the environment settings.
    private let environmentService: EnvironmentService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used to manage syncing and updates to the user's folders.
    private let folderService: FolderService

    /// The service used to manage syncing and updates to the user's organizations.
    private let organizationService: OrganizationService

    /// The service for managing the polices for the user.
    private let policyService: PolicyService

    /// The service used by the application to manage user settings.
    let settingsService: SettingsService

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The service used to handle syncing vault data with the API.
    private let syncService: SyncService

    /// The service used to get the present time.
    private let timeProvider: TimeProvider

    /// The factory to create vault list director strategies.
    private let vaultListDirectorStrategyFactory: VaultListDirectorStrategyFactory

    /// The service used by the application to manage vault access.
    private let vaultTimeoutService: VaultTimeoutService

    // MARK: Initialization

    /// Initialize a `DefaultVaultRepository`.
    ///
    /// - Parameters:
    ///   - cipherService: The service used to manage syncing and updates to the user's ciphers.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - collectionHelper: The helper functions for collections.
    ///   - collectionService: The service for managing the collections for the user.
    ///   - configService: The service to get server-specified configuration.
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - folderService: The service used to manage syncing and updates to the user's folders.
    ///   - organizationService: The service used to manage syncing and updates to the user's organizations.
    ///   - policyService: The service for managing the polices for the user.
    ///   - settingsService: The service used by the application to manage user settings.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///   - timeProvider: The service used to get the present time.
    ///   - vaultListDirectorStrategyFactory: The factory to create vault list director strategies.
    ///   - vaultTimeoutService: The service used by the application to manage vault access.
    ///
    init(
        cipherService: CipherService,
        clientService: ClientService,
        collectionHelper: CollectionHelper,
        collectionService: CollectionService,
        configService: ConfigService,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        folderService: FolderService,
        organizationService: OrganizationService,
        policyService: PolicyService,
        settingsService: SettingsService,
        stateService: StateService,
        syncService: SyncService,
        timeProvider: TimeProvider,
        vaultListDirectorStrategyFactory: VaultListDirectorStrategyFactory,
        vaultTimeoutService: VaultTimeoutService,
    ) {
        self.cipherService = cipherService
        self.clientService = clientService
        self.collectionHelper = collectionHelper
        self.collectionService = collectionService
        self.configService = configService
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.folderService = folderService
        self.organizationService = organizationService
        self.policyService = policyService
        self.settingsService = settingsService
        self.stateService = stateService
        self.syncService = syncService
        self.timeProvider = timeProvider
        self.vaultListDirectorStrategyFactory = vaultListDirectorStrategyFactory
        self.vaultTimeoutService = vaultTimeoutService
    }

    // MARK: Private

    /// Encrypts the cipher. If the cipher was migrated by the SDK (e.g. added a cipher key), the
    /// cipher will be updated locally and on the server.
    ///
    /// - Parameter cipherView: The cipher to encrypt.
    /// - Returns: The encrypted cipher.
    ///
    private func encryptAndUpdateCipher(_ cipherView: CipherView) async throws -> Cipher {
        let cipherEncryptionContext = try await clientService.vault().ciphers().encrypt(cipherView: cipherView)

        let didAddCipherKey = cipherView.key == nil && cipherEncryptionContext.cipher.key != nil
        if didAddCipherKey {
            try await cipherService.updateCipherWithServer(
                cipherEncryptionContext.cipher,
                encryptedFor: cipherEncryptionContext.encryptedFor,
            )
        }

        return cipherEncryptionContext.cipher
    }

    /// Downloads, re-encrypts, and re-uploads an attachment without an attachment key so that it
    /// can be shared to an organization.
    ///
    /// - Parameters:
    ///   - attachment: The attachment that will be shared with the organization.
    ///   - cipher: The cipher containing the attachment.
    /// - Returns: The updated attachment with an attachment key that can be moved into the organization.
    ///
    private func fixCipherAttachment(
        _ attachment: AttachmentView,
        cipher: CipherView,
    ) async throws -> CipherView {
        guard let downloadUrl = try await downloadAttachment(
            attachment,
            cipher: cipher,
        ) else {
            throw BitwardenError.dataError("Unable to download attachment")
        }

        guard let cipherId = cipher.id else { throw CipherAPIServiceError.updateMissingId }
        guard let fileName = attachment.fileName else { throw BitwardenError.dataError("Missing filename") }

        let attachmentData = try Data(contentsOf: downloadUrl)
        var updatedCipher = try await saveAttachment(cipherView: cipher, fileData: attachmentData, fileName: fileName)
        try FileManager.default.removeItem(at: downloadUrl)

        if let attachmentId = attachment.id,
           let cipher = try await deleteAttachment(withId: attachmentId, cipherId: cipherId) {
            updatedCipher = cipher
        }

        return updatedCipher
    }
}

extension DefaultVaultRepository: VaultRepository {
    // MARK: API Methods

    func fetchSync(forceSync: Bool, filter: VaultFilterType, isPeriodic: Bool) async throws {
        let allowSyncOnRefresh = try await stateService.getAllowSyncOnRefresh()
        guard !forceSync || allowSyncOnRefresh else { return }
        try await syncService.fetchSync(forceSync: forceSync, isPeriodic: isPeriodic)
    }

    // MARK: Data Methods

    func addCipher(_ cipher: CipherView) async throws {
        let cipherEncryptionContext = try await clientService.vault().ciphers().encrypt(cipherView: cipher)
        try await cipherService.addCipherWithServer(
            cipherEncryptionContext.cipher,
            encryptedFor: cipherEncryptionContext.encryptedFor,
        )
    }

    func archiveCipher(_ cipher: BitwardenSdk.CipherView) async throws {
        guard let id = cipher.id else {
            throw CipherAPIServiceError.updateMissingId
        }
        let archivedCipher = cipher.update(archivedDate: timeProvider.presentTime)
        let encryptCipher = try await encryptAndUpdateCipher(archivedCipher)
        try await cipherService.archiveCipherWithServer(id: id, encryptCipher)
    }

    func bulkShareCiphers(
        _ ciphers: [CipherView],
        newOrganizationId: String,
        newCollectionIds: [String],
    ) async throws {
        var preparedCiphers = [CipherView]()

        for cipher in ciphers {
            // Ensure the cipher has a cipher key.
            let encryptedCipher = try await encryptAndUpdateCipher(cipher)
            var cipherView = try await clientService.vault().ciphers().decrypt(cipher: encryptedCipher)

            // Migrate any attachments without an encryption key.
            if let attachments = cipherView.attachments {
                for attachment in attachments where attachment.key == nil {
                    cipherView = try await fixCipherAttachment(
                        attachment,
                        cipher: cipherView,
                    )
                }
            }

            preparedCiphers.append(cipherView)
        }

        // Use the SDK to prepare and encrypt all ciphers for bulk share.
        // The SDK handles moveToOrganization internally.
        let encryptionContexts = try await clientService.vault().ciphers()
            .prepareCiphersForBulkShare(
                ciphers: preparedCiphers,
                organizationId: newOrganizationId,
                collectionIds: newCollectionIds,
            )

        guard let encryptedFor = encryptionContexts.first?.encryptedFor else {
            return
        }

        try await cipherService.bulkShareCiphersWithServer(
            encryptionContexts.map(\.cipher),
            collectionIds: newCollectionIds,
            encryptedFor: encryptedFor,
        )
    }

    func canShowVaultFilter() async -> Bool {
        let disablePersonalOwnership = await policyService.policyAppliesToUser(.personalOwnership)
        let singleOrg = await policyService.policyAppliesToUser(.onlyOrg)
        return !(disablePersonalOwnership && singleOrg)
    }

    func clearTemporaryDownloads() {
        Task {
            do {
                let userId = try await stateService.getActiveAccountId()
                let url = try FileManager.default.attachmentsUrl(for: userId)
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
            } catch {
                errorReporter.log(error: error)
            }
        }
    }

    func createAutofillListExcludedCredentialSection(from cipher: CipherView) async throws -> VaultListSection {
        let vaultListItem = try await createFido2VaultListItem(from: cipher)

        return VaultListSection(
            id: Localizations.aPasskeyAlreadyExistsForThisApplication,
            items: [vaultListItem].compactMap(\.self),
            name: Localizations.aPasskeyAlreadyExistsForThisApplication,
        )
    }

    func fetchCipher(withId id: String) async throws -> CipherView? {
        guard let cipher = try await cipherService.fetchCipher(withId: id) else { return nil }
        return try? await clientService.vault().ciphers().decrypt(cipher: cipher)
    }

    func fetchCipherOwnershipOptions(includePersonal: Bool) async throws -> [CipherOwner] {
        let organizations = try await organizationService.fetchAllOrganizations()
        let organizationOwners: [CipherOwner] = organizations
            .filter { $0.enabled && $0.status == .confirmed }
            .map { organization in
                CipherOwner.organization(id: organization.id, name: organization.name)
            }

        if includePersonal {
            let email = try await stateService.getActiveAccount().profile.email
            let personalOwner = CipherOwner.personal(email: email)
            return [personalOwner] + organizationOwners
        } else {
            return organizationOwners
        }
    }

    func fetchCollections(includeReadOnly: Bool) async throws -> [CollectionView] {
        let rawCollections = try await collectionService.fetchAllCollections(includeReadOnly: includeReadOnly)
        let collections = try await clientService.vault().collections()
            .decryptList(collections: rawCollections)
        return try await collectionHelper.order(collections)
    }

    func deleteCipher(_ id: String) async throws {
        try await cipherService.deleteCipherWithServer(id: id)
    }

    func fetchFolder(withId id: String) async throws -> FolderView? {
        guard let folder = try await folderService.fetchFolder(id: id) else {
            return nil
        }
        return try await clientService.vault().folders().decrypt(folder: folder)
    }

    func fetchFolders() async throws -> [FolderView] {
        let folders = try await folderService.fetchAllFolders()
        return try await clientService.vault().folders()
            .decryptList(folders: folders)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func deleteAttachment(withId attachmentId: String, cipherId: String) async throws -> CipherView? {
        // Delete the attachment and then decrypt the resulting updated cipher.
        if let updatedCipher = try await cipherService.deleteAttachmentWithServer(
            attachmentId: attachmentId,
            cipherId: cipherId,
        ) {
            return try await clientService.vault().ciphers().decrypt(cipher: updatedCipher)
        }
        // This would only return nil if the cipher somehow doesn't exist in the datastore anymore.
        return nil
    }

    func doesActiveAccountHavePremium() async -> Bool {
        await stateService.doesActiveAccountHavePremium()
    }

    func downloadAttachment(_ attachmentView: AttachmentView, cipher: CipherView) async throws -> URL? {
        let userId = try await stateService.getActiveAccountId()

        guard let attachmentId = attachmentView.id,
              let attachmentName = attachmentView.fileName,
              let cipherId = cipher.id
        else { throw BitwardenError.dataError("Missing data") }

        guard let encryptedCipher = try await cipherService.fetchCipher(withId: cipherId) else {
            throw BitwardenError.dataError("Unable to fetch cipher with ID \(cipherId)")
        }

        guard let downloadedUrl = try await cipherService.downloadAttachment(withId: attachmentId, cipherId: cipherId)
        else { return nil }

        // Create a temporary location to write the decrypted data to.
        let storageUrl = try FileManager.default.attachmentsUrl(for: userId)

        try FileManager.default.createDirectory(at: storageUrl, withIntermediateDirectories: true)
        let temporaryUrl = storageUrl.appendingPathComponent(attachmentName)

        // Decrypt the downloaded data and move it to the specified temporary location.
        try await clientService.vault().attachments().decryptFile(
            cipher: encryptedCipher,
            attachment: attachmentView,
            encryptedFilePath: downloadedUrl.path,
            decryptedFilePath: temporaryUrl.path,
        )

        // Remove the encrypted file.
        try FileManager.default.removeItem(at: downloadedUrl)

        // Return the temporary location where the downloaded data is located.
        return temporaryUrl
    }

    func fetchOrganization(withId id: String) async throws -> Organization? {
        let organizations = try await organizationService.fetchAllOrganizations()
        return organizations.first(where: { $0.id == id })
    }

    func getItemTypesUserCanCreate() async -> [CipherType] {
        let itemTypes: [CipherType] = CipherType.canCreateCases.reversed()
        let restrictItemTypesOrgIds = await policyService.getOrganizationIdsForRestricItemTypesPolicy()
        if !restrictItemTypesOrgIds.isEmpty {
            return itemTypes.filter { $0 != .card }
        }

        return itemTypes
    }

    func getDisableAutoTotpCopy() async throws -> Bool {
        try await stateService.getDisableAutoTotpCopy()
    }

    func getTOTPKeyIfAllowedToCopy(cipher: CipherView) async throws -> String? {
        guard let totp = cipher.login?.totp else {
            return nil
        }

        guard try await getDisableAutoTotpCopy() == false else {
            return nil
        }

        let accountHavePremium = await doesActiveAccountHavePremium()
        if !cipher.organizationUseTotp, !accountHavePremium {
            return nil
        }

        return totp
    }

    func isVaultEmpty() async throws -> Bool {
        try await cipherService.cipherCount() == 0
    }

    func migratePersonalVault(to organizationId: String) async throws {
        // Fetch collections and find the default collection for the organization.
        let collections = try await fetchCollections(includeReadOnly: false)
        guard let defaultCollection = collections.first(where: { collection in
            collection.organizationId == organizationId && collection.type == .defaultUserCollection
        }), let collectionId = defaultCollection.id else {
            throw BitwardenError.dataError("No default collection found for organization \(organizationId)")
        }

        // Fetch all ciphers and filter to get personal vault items.
        let allCiphers = try await cipherService.fetchAllCiphers()
        let personalCiphers = allCiphers.filter { cipher in
            cipher.organizationId == nil
        }

        guard !personalCiphers.isEmpty else {
            return
        }

        // Decrypt personal ciphers to CipherViews.
        let cipherViews = try await personalCiphers.asyncMap { cipher in
            try await clientService.vault().ciphers().decrypt(cipher: cipher)
        }

        // Share all personal vault ciphers with the organization's default collection.
        try await bulkShareCiphers(cipherViews, newOrganizationId: organizationId, newCollectionIds: [collectionId])
    }

    func needsSync() async throws -> Bool {
        let userId = try await stateService.getActiveAccountId()
        return try await syncService.needsSync(for: userId, onlyCheckLocalData: true)
    }

    func refreshTOTPCode(for key: TOTPKeyModel) async throws -> LoginTOTPState {
        let codeState = try await clientService.vault().generateTOTPCode(
            for: key.rawAuthenticatorKey,
            date: timeProvider.presentTime,
        )
        return LoginTOTPState(
            authKeyModel: key,
            codeModel: codeState,
        )
    }

    func refreshTOTPCodes(for items: [VaultListItem]) async throws -> [VaultListItem] {
        await items.asyncMap { item in
            guard case let .totp(name, model) = item.itemType,
                  model.cipherListView.type.loginListView?.totp != nil,
                  let vault = try? await clientService.vault(),
                  let code = try? vault.generateTOTPCode(for: model.cipherListView, date: timeProvider.presentTime)
            else {
                errorReporter.log(error: TOTPServiceError
                                    .unableToGenerateCode("Unable to refresh TOTP code for list view item: \(item.id)"))
                return item
            }
            var updatedModel = model
            updatedModel.totpCode = code
            return .init(
                id: item.id,
                itemType: .totp(name: name, totpModel: updatedModel),
            )
        }
        .sorted { $0.sortValue.localizedStandardCompare($1.sortValue) == .orderedAscending }
    }

    func repromptRequiredForCipher(id: String) async throws -> Bool {
        guard try await stateService.getUserHasMasterPassword() else { return false }
        let cipher = try await cipherService.fetchCipher(withId: id)
        return cipher?.reprompt == .password
    }

    func restoreCipher(_ cipher: BitwardenSdk.CipherView) async throws {
        guard let id = cipher.id else { throw CipherAPIServiceError.updateMissingId }
        let restoredCipher = cipher.update(deletedDate: nil)
        let encryptCipher = try await encryptAndUpdateCipher(restoredCipher)
        try await cipherService.restoreCipherWithServer(id: id, encryptCipher)
    }

    func saveAttachment(cipherView: CipherView, fileData: Data, fileName: String) async throws -> CipherView {
        // Put the file data size and file name into a blank attachment view.
        let attachmentView = AttachmentView(
            id: nil,
            url: nil,
            size: "\(fileData.count)",
            sizeName: nil,
            fileName: fileName,
            key: nil,
        )

        // Encrypt the attachment.
        let cipher = try await encryptAndUpdateCipher(cipherView)
        let attachment = try await clientService.vault().attachments().encryptBuffer(
            cipher: cipher,
            attachment: attachmentView,
            buffer: fileData,
        )

        // Save the attachment to the cipher and return the updated cipher.
        let updatedCipher = try await cipherService.saveAttachmentWithServer(
            cipher: cipher,
            attachment: attachment,
        )
        return try await clientService.vault().ciphers().decrypt(cipher: updatedCipher)
    }

    func shareCipher(_ cipherView: CipherView, newOrganizationId: String, newCollectionIds: [String]) async throws {
        // Ensure the cipher has a cipher key.
        let encryptedCipher = try await encryptAndUpdateCipher(cipherView)
        var cipherView = try await clientService.vault().ciphers().decrypt(cipher: encryptedCipher)

        if let attachments = cipherView.attachments {
            for attachment in attachments where attachment.key == nil {
                // When moving a cipher to an organization, any attachments without an encryption
                // key need to be re-encrypted with an attachment key.
                cipherView = try await fixCipherAttachment(
                    attachment,
                    cipher: cipherView,
                )
            }
        }

        let organizationCipher = try await clientService.vault().ciphers()
            .moveToOrganization(
                cipher: cipherView,
                organizationId: newOrganizationId,
            )
            .update(collectionIds: newCollectionIds) // The SDK updates the cipher's organization ID.

        let organizationCipherEncryptionContext = try await clientService.vault().ciphers()
            .encrypt(cipherView: organizationCipher)
        try await cipherService.shareCipherWithServer(
            organizationCipherEncryptionContext.cipher,
            encryptedFor: organizationCipherEncryptionContext.encryptedFor,
        )
    }

    func softDeleteCipher(_ cipher: CipherView) async throws {
        guard let id = cipher.id else { throw CipherAPIServiceError.updateMissingId }
        let softDeletedCipher = cipher.update(deletedDate: timeProvider.presentTime)
        let encryptedCipher = try await encryptAndUpdateCipher(softDeletedCipher)
        try await cipherService.softDeleteCipherWithServer(id: id, encryptedCipher)
    }

    func unarchiveCipher(_ cipher: BitwardenSdk.CipherView) async throws {
        guard let id = cipher.id else {
            throw CipherAPIServiceError.updateMissingId
        }
        let archivedCipher = cipher.update(archivedDate: nil)
        let encryptCipher = try await encryptAndUpdateCipher(archivedCipher)
        try await cipherService.unarchiveCipherWithServer(id: id, encryptCipher)
    }

    func updateCipher(_ cipherView: CipherView) async throws {
        let cipherEncryptionContext = try await clientService.vault().ciphers().encrypt(cipherView: cipherView)
        try await cipherService.updateCipherWithServer(
            cipherEncryptionContext.cipher,
            encryptedFor: cipherEncryptionContext.encryptedFor,
        )
    }

    func updateCipherCollections(_ cipherView: CipherView) async throws {
        let cipher = try await encryptAndUpdateCipher(cipherView)
        try await cipherService.updateCipherCollectionsWithServer(cipher)
    }

    // MARK: Publishers

    func cipherPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[CipherListView], Error>> {
        try await cipherService.ciphersPublisher()
            .asyncTryMap { ciphers in
                try await self.clientService.vault().ciphers().decryptListWithFailures(ciphers: ciphers)
                    .successes
                    .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            }
            .eraseToAnyPublisher()
            .values
    }

    func cipherDetailsPublisher(id: String) async throws -> AsyncThrowingPublisher<AnyPublisher<CipherView?, Error>> {
        try await cipherService.ciphersPublisher()
            .asyncTryMap { ciphers -> CipherView? in
                guard let cipher = ciphers.first(where: { $0.id == id }) else { return nil }
                return try await self.clientService.vault().ciphers().decrypt(cipher: cipher)
            }
            .eraseToAnyPublisher()
            .values
    }

    func ciphersAutofillPublisher(
        availableFido2CredentialsPublisher: AnyPublisher<[BitwardenSdk.CipherView]?, Error>,
        mode: AutofillListMode,
        group: VaultListGroup? = nil,
        rpID: String?,
        uri: String?,
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>> {
        switch mode {
        case .all:
            try await vaultListPublisher(
                filter: VaultListFilter(
                    filterType: .allVaults,
                    group: group,
                ),
            )
        case .combinedMultipleSections, .combinedSingleSection, .passwords:
            try await vaultListPublisher(
                filter: VaultListFilter(
                    filterType: .allVaults,
                    mode: mode,
                    rpID: rpID,
                    uri: uri,
                ),
            )
        case .totp:
            try await vaultListPublisher(
                filter: VaultListFilter(
                    group: .totp,
                ),
            )
        }
    }

    func organizationsPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[Organization], Error>> {
        try await organizationService.organizationsPublisher().eraseToAnyPublisher().values
    }

    func vaultListPublisher(
        filter: VaultListFilter,
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>> {
        try await vaultListDirectorStrategyFactory
            .make(filter: filter)
            .build(filter: filter)
    }

    func vaultSearchListPublisher(
        mode: AutofillListMode?,
        filterPublisher: AnyPublisher<VaultListFilter, Error>,
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>> {
        try await vaultListDirectorStrategyFactory
            .makeSearchStrategy(mode: mode)
            .build(filterPublisher: filterPublisher)
    }

    // MARK: Private

    /// Creates a `VaultListItem` from a `CipherView` with Fido2 credentials.
    /// - Parameter cipher: Cipher from which create the item.
    /// - Returns: The `VaultListItem` with the cipher and Fido2 credentials.
    private func createFido2VaultListItem(from cipherView: CipherView) async throws -> VaultListItem? {
        guard let id = cipherView.id, let cipher = try await cipherService.fetchCipher(withId: id) else {
            return nil
        }
        let decryptedCipherListViews = try await clientService.vault().ciphers()
            .decryptListWithFailures(ciphers: [cipher]).successes
        guard let cipherListView = decryptedCipherListViews.first else {
            return nil
        }

        return try await createFido2VaultListItem(cipherListView: cipherListView, cipherView: cipherView)
    }

    /// Creates a `VaultListItem` from a `CipherListView` with Fido2 credentials.
    /// - Parameter cipher: Cipher from which create the item.
    /// - Returns: The `VaultListItem` with the cipher and Fido2 credentials.
    private func createFido2VaultListItem(from cipherListView: CipherListView) async throws -> VaultListItem? {
        guard let id = cipherListView.id, let cipherView = try await fetchCipher(withId: id) else {
            return nil
        }
        return try await createFido2VaultListItem(cipherListView: cipherListView, cipherView: cipherView)
    }

    /// Creates a `VaultListItem` from a cipher with Fido2 credentials.
    /// We need both `CipherListView` and `CipherView` to get
    /// all the info.
    /// - Parameters:
    ///   - cipherListView: Cipher from which create the item.
    ///   - cipherView: Cipher from which get the autofill data.
    /// - Returns: The `VaultListItem` with the cipher and Fido2 credentials.
    private func createFido2VaultListItem(
        cipherListView: CipherListView,
        cipherView: CipherView,
    ) async throws -> VaultListItem? {
        let decryptedFido2Credentials = try await clientService
            .platform()
            .fido2()
            .decryptFido2AutofillCredentials(cipherView: cipherView, encryptionKey: nil)

        guard let fido2CredentialAutofillView = decryptedFido2Credentials.first else {
            errorReporter.log(error: Fido2Error.decryptFido2AutofillCredentialsEmpty)
            return nil
        }

        return VaultListItem(
            cipherListView: cipherListView,
            fido2CredentialAutofillView: fido2CredentialAutofillView,
        )
    }
} // swiftlint:disable:this file_length
