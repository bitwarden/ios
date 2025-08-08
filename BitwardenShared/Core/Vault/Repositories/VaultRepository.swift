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
        cipher: CipherView
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
        id: String
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
        uri: String?
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

    /// A publisher for searching a user's cipher objects for autofill. This only includes login ciphers.
    ///
    /// - Parameters:
    ///   - availableFido2CredentialsPublisher: The publisher for available Fido2 credentials for Fido2 autofill list.
    ///   - mode: The mode in which the autofill list is presented.
    ///   - filter: The vault filter to apply to the cipher list.
    ///   - rpID: The relying party identifier of the Fido2 request
    ///   - searchText: The search text to filter the cipher list.
    ///
    /// - Returns: A publisher for searching the user's ciphers for autofill.
    func searchCipherAutofillPublisher( // swiftlint:disable:this function_parameter_count
        availableFido2CredentialsPublisher: AnyPublisher<[BitwardenSdk.CipherView]?, Error>,
        mode: AutofillListMode,
        filter: VaultListFilter,
        group: VaultListGroup?,
        rpID: String?,
        searchText: String
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>>

    /// A publisher for searching a user's cipher objects based on the specified search text and filter type.
    ///
    /// - Parameters:
    ///     - searchText:  The search text to filter the cipher list.
    ///     - group: The group to search. Searches all groups if nil.
    ///     - filter: The vault filter to apply to the cipher list.
    /// - Returns: A publisher searching for the user's ciphers.
    ///
    func searchVaultListPublisher(
        searchText: String,
        group: VaultListGroup?,
        filter: VaultListFilter
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListItem], Error>>

    /// A publisher for the vault list which returns a list of sections and items that are
    /// displayed in the vault.
    ///
    /// - Parameter filter: A filter to apply to the vault items.
    /// - Returns: A publisher for the sections of the vault list which will be notified as the
    ///     data changes.
    ///
    func vaultListPublisher(
        filter: VaultListFilter
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

    /// A publisher for searching a user's cipher objects based on the specified search text and filter type.
    ///
    /// - Parameters:
    ///     - searchText:  The search text to filter the cipher list.
    ///     - filter: The vault filter type to apply to the cipher list.
    /// - Returns: A publisher searching for the user's ciphers.
    ///
    func searchVaultListPublisher(
        searchText: String,
        filter: VaultListFilter
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListItem], Error>> {
        try await searchVaultListPublisher(
            searchText: searchText,
            group: nil,
            filter: filter
        )
    }
}

/// A default implementation of a `VaultRepository`.
///
class DefaultVaultRepository { // swiftlint:disable:this type_body_length
    // MARK: Properties

    /// The service used to manage syncing and updates to the user's ciphers.
    private let cipherService: CipherService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service to get server-specified configuration.
    private let configService: ConfigService

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
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.cipherService = cipherService
        self.clientService = clientService
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
                encryptedFor: cipherEncryptionContext.encryptedFor
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
        cipher: CipherView
    ) async throws -> CipherView {
        guard let downloadUrl = try await downloadAttachment(
            attachment,
            cipher: cipher
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

    /// Returns a list of `VaultListItem`s for the folders within a nested tree. By default, this
    /// will return the list items for the folders at the root of the tree. Specifying a
    /// `nestedFolderId` will return the list items for the children of the folder with the
    /// specified ID.
    ///
    /// - Parameters:
    ///   - activeCiphers: The list of active (non-deleted) ciphers, used to determine the count of
    ///     ciphers within a folder.
    ///   - folderTree: The nested tree of folders.
    ///   - nestedFolderId: An optional folder ID of a nested folder to create the list items from
    ///     the children of that folder. Defaults to `nil` which will return the list items for the
    ///     folders at the root of the tree.
    /// - Returns: A list of `VaultListItem`s for the folders within a nested tree.
    ///
    private func folderVaultListItems(
        activeCiphers: [CipherListView],
        folderTree: Tree<FolderView>,
        nestedFolderId: String? = nil
    ) -> [VaultListItem] {
        let folders: [TreeNode<FolderView>]? = if let nestedFolderId {
            folderTree.getTreeNodeObject(with: nestedFolderId)?.children
        } else {
            folderTree.rootNodes
        }

        guard let folders else { return [] }

        return folders.compactMap { folderNode in
            guard let folderId = folderNode.node.id else {
                self.errorReporter.log(
                    error: BitwardenError.dataError("Received a folder from the API with a missing ID.")
                )
                return nil
            }
            let cipherCount = activeCiphers.lazy.filter { $0.folderId == folderId }.count
            return VaultListItem(
                id: folderId,
                itemType: .group(.folder(id: folderId, name: folderNode.name), cipherCount)
            )
        }
    }

    /// A publisher for searching a user's ciphers based on the specified search text and filter type.
    ///
    /// - Parameters:
    ///   - searchText: The search text to filter the cipher list.
    ///   - filter: The vault filter to apply to the cipher list.
    ///   - cipherFilter: An optional additional filter to apply to the cipher list.
    /// - Returns: A publisher searching for the user's ciphers.
    ///
    private func searchPublisher(
        searchText: String,
        filter: VaultListFilter,
        isActive: Bool,
        cipherFilter: ((CipherListView) -> Bool)? = nil
    ) async throws -> AnyPublisher<[CipherListView], Error> {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        let isMatchingCipher: (CipherListView) -> Bool = isActive
            ? { $0.deletedDate == nil }
            : { $0.deletedDate != nil }
        let restrictItemTypesOrgIds = await getRestrictItemTypesOrgIds()

        return try await cipherService.ciphersPublisher().asyncTryMap { ciphers -> [CipherListView] in
            // Convert the Ciphers to CipherViews and filter appropriately.
            let matchingCiphers = try await self.clientService.vault().ciphers()
                .decryptListWithFailures(ciphers: ciphers).successes
                .filter { cipher in
                    filter.filterType.cipherFilter(cipher) &&
                        isMatchingCipher(cipher) &&
                        (cipherFilter?(cipher) ?? true) &&
                        self.filterBasedOnRestrictItemTypesPolicy(cipher: cipher, restrictItemTypesOrgIds)
                }

            var matchedCiphers: [CipherListView] = []
            var lowPriorityMatchedCiphers: [CipherListView] = []

            // Search the ciphers.
            matchingCiphers.forEach { cipher in
                if cipher.name.lowercased()
                    .folding(options: .diacriticInsensitive, locale: nil).contains(query) {
                    matchedCiphers.append(cipher)
                } else if query.count >= 8, cipher.id?.starts(with: query) == true {
                    lowPriorityMatchedCiphers.append(cipher)
                } else if cipher.subtitle.lowercased()
                    .folding(options: .diacriticInsensitive, locale: nil).contains(query) == true {
                    lowPriorityMatchedCiphers.append(cipher)
                } else if cipher.type.loginListView?.uris?
                    .contains(where: { $0.uri?.contains(query) == true }) == true {
                    lowPriorityMatchedCiphers.append(cipher)
                }
            }

            // Return the result.
            return matchedCiphers.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending } +
                lowPriorityMatchedCiphers
        }.eraseToAnyPublisher()
    }

    /// Returns a list of TOTP type items from a SyncResponseModel.
    ///
    /// - Parameters:
    ///   - ciphers: The ciphers containing the list of TOTP keys.
    ///   - filter: The filter applied to the response.
    /// - Returns: A list of totpKey type items in the vault list.
    ///
    private func totpListItems(
        from ciphers: [CipherListView],
        filter: VaultFilterType?
    ) async throws -> [VaultListItem] {
        let hasPremiumFeaturesAccess = await doesActiveAccountHavePremium()
        let userHasMasterPassword = await (try? stateService.getUserHasMasterPassword()) ?? false

        // Filter and sort the list.
        let activeCiphers = ciphers
            .filter(filter?.cipherFilter(_:) ?? { _ in true })
            .filter { cipher in
                cipher.deletedDate == nil
                    && cipher.type.loginListView?.totp != nil
                    && (hasPremiumFeaturesAccess || cipher.organizationUseTotp)
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        // Convert the CipherViews into VaultListItem.
        let totpItems: [VaultListItem] = try await activeCiphers
            .asyncMap { try await totpItem(for: $0, userHasMasterPassword: userHasMasterPassword) }
            .compactMap { $0 }

        return totpItems
    }

    /// A transform to convert a `CipherListView` into a TOTP `VaultListItem`.
    ///
    /// - Parameters:
    ///   - cipherListView: The cipher view that may have a TOTP key.
    ///   - userHasMasterPassword: Whether the user has a master password.
    /// - Returns: A `VaultListItem` if the cipher supports TOTP.
    ///
    private func totpItem(
        for cipherListView: CipherListView,
        userHasMasterPassword: Bool
    ) async throws -> VaultListItem? {
        guard let id = cipherListView.id,
              cipherListView.type.loginListView?.totp != nil else {
            return nil
        }
        guard let code = try? await clientService.vault().generateTOTPCode(
            for: cipherListView,
            date: timeProvider.presentTime
        ) else {
            errorReporter.log(
                error: TOTPServiceError
                    .unableToGenerateCode("Unable to create TOTP code for cipher id \(id)")
            )
            return nil
        }

        let listModel = VaultListTOTP(
            id: id,
            cipherListView: cipherListView,
            requiresMasterPassword: cipherListView.reprompt == .password && userHasMasterPassword,
            totpCode: code
        )
        return VaultListItem(
            id: id,
            itemType: .totp(
                name: cipherListView.name,
                totpModel: listModel
            )
        )
    }

    /// Returns a `VaultListSection` for the collection section, if one exists.
    ///
    /// - Parameters:
    ///   - activeCiphers: The list of active (non-deleted) ciphers, used to determine the count of
    ///     ciphers within a collection.
    ///   - collections: The list of all collections.
    ///   - filter: A filter to apply to the vault items.
    ///   - nestedCollectionId: An optional collection ID of a nested collection to create the list
    ///     items from the children of that collection. Defaults to `nil` which will return the list
    ///     of collections at the root of the tree.
    /// - Returns: A `VaultListSection` for the collection section, if one exists.
    ///
    private func vaultListCollectionSection(
        activeCiphers: [CipherListView],
        collections: [Collection],
        filter: VaultFilterType,
        nestedCollectionId: String? = nil
    ) async throws -> VaultListSection? {
        let decryptedCollections = try await clientService.vault().collections()
            .decryptList(collections: collections)
            .filter(filter.collectionFilter)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        let collectionTree = decryptedCollections.asNestedNodes()

        let nestedCollections = if let nestedCollectionId {
            collectionTree.getTreeNodeObject(with: nestedCollectionId)?.children
        } else {
            collectionTree.rootNodes
        }

        guard let nestedCollections else { return nil }

        let collectionItems: [VaultListItem] = nestedCollections.compactMap { collectionNode in
            let collection = collectionNode.node
            guard let collectionId = collection.id else {
                self.errorReporter.log(
                    error: BitwardenError.dataError("Received a collection from the API with a missing ID.")
                )
                return nil
            }
            let collectionCount = activeCiphers.lazy.filter { $0.collectionIds.contains(collectionId) }.count
            return VaultListItem(
                id: collectionId,
                itemType: .group(
                    .collection(id: collectionId, name: collectionNode.name, organizationId: collection.organizationId),
                    collectionCount
                )
            )
        }

        return VaultListSection(id: "Collections", items: collectionItems, name: Localizations.collections)
    }

    /// Returns a `VaultListSection` for the folder section, if one exists.
    ///
    /// - Parameters:
    ///   - activeCiphers: The list of active (non-deleted) ciphers, used to determine the count of
    ///     ciphers within a folder.
    ///   - group: The group of items to get.
    ///   - filter: A filter to apply to the vault items.
    ///   - folders: The list of all folders. This is used to show any nested folders within a
    ///     folder group.
    /// - Returns: A `VaultListSection` for the folder section, if one exists.
    ///
    private func vaultListFolderSection(
        activeCiphers: [CipherListView],
        group: VaultListGroup,
        filter: VaultFilterType,
        folders: [Folder]
    ) async throws -> VaultListSection? {
        guard let folderId = group.folderId else { return nil }

        let folders = try await clientService.vault().folders()
            .decryptList(folders: folders)
            .filter { filter.folderFilter($0, ciphers: activeCiphers) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let folderItems = folderVaultListItems(
            activeCiphers: activeCiphers,
            folderTree: folders.asNestedNodes(),
            nestedFolderId: folderId
        )

        return VaultListSection(
            id: "Folders",
            items: folderItems,
            name: Localizations.folder
        )
    }

    /// Returns a `VaultListSection` for the vault items section.
    ///
    /// - Parameters:
    ///   - activeCiphers: The list of active (non-deleted) ciphers.
    ///   - deletedCiphers: The list of deleted ciphers.
    ///   - group: The group of items to get.
    ///   - filter: A filter to apply to the vault items.
    /// - Returns: A `VaultListSection` for the vault items section.
    ///
    private func vaultListItemsSection(
        activeCiphers: [CipherListView],
        deletedCiphers: [CipherListView],
        group: VaultListGroup,
        filter: VaultFilterType
    ) async throws -> VaultListSection {
        let items: [VaultListItem]
        switch group {
        case .card:
            items = activeCiphers.filter(\.type.isCard).compactMap(VaultListItem.init)
        case let .collection(id, _, _):
            items = activeCiphers.filter { $0.collectionIds.contains(id) }.compactMap(VaultListItem.init)
        case let .folder(id, _):
            items = activeCiphers.filter { $0.folderId == id }.compactMap(VaultListItem.init)
        case .identity:
            items = activeCiphers.filter { $0.type == .identity }.compactMap(VaultListItem.init)
        case .login:
            items = activeCiphers.filter(\.type.isLogin).compactMap(VaultListItem.init)
        case .noFolder:
            items = activeCiphers.filter { $0.folderId == nil }.compactMap(VaultListItem.init)
        case .secureNote:
            items = activeCiphers.filter { $0.type == .secureNote }.compactMap(VaultListItem.init)
        case .sshKey:
            items = activeCiphers.filter { $0.type == .sshKey }.compactMap(VaultListItem.init)
        case .totp:
            items = try await totpListItems(from: activeCiphers, filter: filter)
        case .trash:
            items = deletedCiphers.compactMap(VaultListItem.init)
        }

        return VaultListSection(id: "Items", items: items, name: Localizations.items)
    }

    /// Returns a list of sections containing the items that are grouped together in the vault list
    /// from a list of encrypted ciphers.
    ///
    /// - Parameters:
    ///   - group: The group of items to get.
    ///   - filter: A filter to apply to the vault items.
    ///   - ciphers: The ciphers to build the list of items.
    ///   - folders: The list of all folders. This is used to show any nested folders within a
    ///     folder group.
    /// - Returns: A list of items for the group in the vault list.
    ///
    private func vaultListItems(
        group: VaultListGroup,
        filter: VaultListFilter,
        ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder] = []
    ) async throws -> [VaultListSection] {
        let restrictItemTypesOrgIds = await getRestrictItemTypesOrgIds()
        let ciphers = try await clientService.vault().ciphers().decryptListWithFailures(ciphers: ciphers)
            .successes
            .filter { cipher in
                filter.filterType.cipherFilter(cipher) &&
                    filterBasedOnRestrictItemTypesPolicy(cipher: cipher, restrictItemTypesOrgIds)
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let activeCiphers = ciphers.filter { $0.deletedDate == nil }
        let deletedCiphers = ciphers.filter { $0.deletedDate != nil }

        let folderSection = try await vaultListFolderSection(
            activeCiphers: activeCiphers,
            group: group,
            filter: filter.filterType,
            folders: folders
        )

        let collectionSection: VaultListSection? = if let collectionId = group.collectionId {
            try await vaultListCollectionSection(
                activeCiphers: activeCiphers,
                collections: collections,
                filter: filter.filterType,
                nestedCollectionId: collectionId
            )
        } else {
            nil
        }

        let itemsSection = try await vaultListItemsSection(
            activeCiphers: activeCiphers,
            deletedCiphers: deletedCiphers,
            group: group,
            filter: filter.filterType
        )

        return [
            folderSection,
            collectionSection,
            itemsSection,
        ]
        .compactMap { $0 }
        .filter { !$0.items.isEmpty }
    }

    /// Filters ciphers based on the organization's restrictItemTypes policy.
    ///
    /// - Parameters:
    ///  - cipher: The cipher to check against the policy.
    ///  - restrictItemTypesOrgIds: The list of organization IDs that are restricted by the policy.
    ///  - Returns: `true` if the cipher is allowed by the policy, `false` otherwise.
    ///
    func filterBasedOnRestrictItemTypesPolicy(cipher: CipherListView, _ restrictItemTypesOrgIds: [String]) -> Bool {
        guard !restrictItemTypesOrgIds.isEmpty, cipher.type.isCard else { return true }
        guard let orgId = cipher.organizationId, !orgId.isEmpty else { return false }
        return !restrictItemTypesOrgIds.contains(orgId)
    }

    /// If `FeatureFlag.removeCardPolicy` feature flag is enabled, gets the organization IDs that have the
    /// `PolicyType.restrictItemTypes` policy active.
    ///
    /// - Returns: A list of organization IDs that have the restrictItemTypes policy enabled.
    private func getRestrictItemTypesOrgIds() async -> [String] {
        guard await configService.getFeatureFlag(.removeCardPolicy) else { return [] }
        return await policyService.getOrganizationIdsForRestricItemTypesPolicy()
    }

    /// Returns a list of the sections in the vault list from a sync response.
    ///
    /// - Parameters:
    ///   - ciphers: The encrypted ciphers in the user's vault.
    ///   - collections: The encrypted list of collections the user has access to.
    ///   - folders: The encrypted list of folders the user has.
    ///   - filter: A filter to apply to the vault items.
    /// - Returns: A list of the sections to display in the vault list.
    ///
    private func vaultListSections( // swiftlint:disable:this function_body_length
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter
    ) async throws -> [VaultListSection] {
        let restrictItemTypesOrgIds = await getRestrictItemTypesOrgIds()
        let ciphers = try await clientService.vault().ciphers().decryptListWithFailures(ciphers: ciphers)
            .successes
            .filter { cipher in
                filter.filterType.cipherFilter(cipher) &&
                    filterBasedOnRestrictItemTypesPolicy(cipher: cipher, restrictItemTypesOrgIds)
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        guard !ciphers.isEmpty else { return [] }

        let activeCiphers = ciphers.filter { cipher in
            cipher.deletedDate == nil
        }

        let folders = try await clientService.vault().folders()
            .decryptList(folders: folders)
            .filter { filter.filterType.folderFilter($0, ciphers: activeCiphers) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        var sections: [VaultListSection] = []

        let ciphersFavorites = activeCiphers.filter(\.favorite).compactMap(VaultListItem.init)
        let ciphersNoFolder = activeCiphers.filter { $0.folderId == nil }.compactMap(VaultListItem.init)

        if filter.addTOTPGroup {
            // Add TOTP items for premium accounts (or if organization uses TOTP without premium).
            let totpItemsCount = try await totpListItems(from: ciphers, filter: filter.filterType).count
            let totpItems = [totpItemsCount].filter { $0 > 0 }.map { count in
                VaultListItem(
                    id: "Types.VerificationCodes",
                    itemType: .group(.totp, count)
                )
            }
            sections.append(VaultListSection(id: "TOTP", items: totpItems, name: Localizations.totp))
        }

        let collectionSection = try await vaultListCollectionSection(
            activeCiphers: activeCiphers,
            collections: collections,
            filter: filter.filterType
        )

        var folderItems = folderVaultListItems(
            activeCiphers: activeCiphers,
            folderTree: folders.asNestedNodes()
        )

        // Add no folder to folders item if needed.
        let showNoFolderCipherGroup = (collectionSection?.items.isEmpty ?? false)
            && ciphersNoFolder.count < Constants.noFolderListSize
        if !showNoFolderCipherGroup {
            folderItems.append(
                VaultListItem(
                    id: "NoFolderFolderItem",
                    itemType: .group(.noFolder, ciphersNoFolder.count)
                )
            )
        }

        let typesCardCount = activeCiphers.lazy.filter(\.type.isCard).count
        let typesIdentityCount = activeCiphers.lazy.filter { $0.type == .identity }.count
        let typesLoginCount = activeCiphers.lazy.filter(\.type.isLogin).count
        let typesSecureNoteCount = activeCiphers.lazy.filter { $0.type == .secureNote }.count
        let typesSSHKeyCount = activeCiphers.lazy.filter { $0.type == .sshKey }.count

        var types = [VaultListItem(id: "Types.Logins", itemType: .group(.login, typesLoginCount))]

        // Only show the card section if there are cards or restrictItemTypes policy is not enabled.
        if typesCardCount != 0 || restrictItemTypesOrgIds.isEmpty {
            types.append(VaultListItem(id: "Types.Cards", itemType: .group(.card, typesCardCount)))
        }

        types.append(contentsOf: [
            VaultListItem(id: "Types.Identities", itemType: .group(.identity, typesIdentityCount)),
            VaultListItem(id: "Types.SecureNotes", itemType: .group(.secureNote, typesSecureNoteCount)),
            VaultListItem(id: "Types.SSHKeys", itemType: .group(.sshKey, typesSSHKeyCount)),
        ])

        sections.append(contentsOf: [
            VaultListSection(id: "Favorites", items: ciphersFavorites, name: Localizations.favorites),
            VaultListSection(id: "Types", items: types, name: Localizations.types),
            VaultListSection(id: "Folders", items: folderItems, name: Localizations.folders),
            VaultListSection(
                id: "NoFolder",
                items: showNoFolderCipherGroup ? ciphersNoFolder : [],
                name: Localizations.folderNone
            ),
        ])
        if let collectionSection {
            sections.append(collectionSection)
        }
        if filter.addTrashGroup {
            let ciphersTrashCount = ciphers.lazy.filter { $0.deletedDate != nil }.count
            let ciphersTrashItem = VaultListItem(id: "Trash", itemType: .group(.trash, ciphersTrashCount))
            sections.append(VaultListSection(id: "Trash", items: [ciphersTrashItem], name: Localizations.trash))
        }

        return sections.filter { !$0.items.isEmpty }
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
            encryptedFor: cipherEncryptionContext.encryptedFor
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
            items: [vaultListItem].compactMap { $0 },
            name: Localizations.aPasskeyAlreadyExistsForThisApplication
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
        let collections = try await collectionService.fetchAllCollections(includeReadOnly: includeReadOnly)
        return try await clientService.vault().collections()
            .decryptList(collections: collections)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
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
            cipherId: cipherId
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
            decryptedFilePath: temporaryUrl.path
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
        guard await configService.getFeatureFlag(.removeCardPolicy) else { return itemTypes }
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

    func needsSync() async throws -> Bool {
        let userId = try await stateService.getActiveAccountId()
        return try await syncService.needsSync(for: userId, onlyCheckLocalData: true)
    }

    func refreshTOTPCode(for key: TOTPKeyModel) async throws -> LoginTOTPState {
        let codeState = try await clientService.vault().generateTOTPCode(
            for: key.rawAuthenticatorKey,
            date: timeProvider.presentTime
        )
        return LoginTOTPState(
            authKeyModel: key,
            codeModel: codeState
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
                itemType: .totp(name: name, totpModel: updatedModel)
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
            key: nil
        )

        // Encrypt the attachment.
        let cipher = try await encryptAndUpdateCipher(cipherView)
        let attachment = try await clientService.vault().attachments().encryptBuffer(
            cipher: cipher,
            attachment: attachmentView,
            buffer: fileData
        )

        // Save the attachment to the cipher and return the updated cipher.
        let updatedCipher = try await cipherService.saveAttachmentWithServer(
            cipher: cipher,
            attachment: attachment
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
                    cipher: cipherView
                )
            }
        }

        let organizationCipher = try await clientService.vault().ciphers()
            .moveToOrganization(
                cipher: cipherView,
                organizationId: newOrganizationId
            )
            .update(collectionIds: newCollectionIds) // The SDK updates the cipher's organization ID.

        let organizationCipherEncryptionContext = try await clientService.vault().ciphers()
            .encrypt(cipherView: organizationCipher)
        try await cipherService.shareCipherWithServer(
            organizationCipherEncryptionContext.cipher,
            encryptedFor: organizationCipherEncryptionContext.encryptedFor
        )
    }

    func softDeleteCipher(_ cipher: CipherView) async throws {
        guard let id = cipher.id else { throw CipherAPIServiceError.updateMissingId }
        let softDeletedCipher = cipher.update(deletedDate: timeProvider.presentTime)
        let encryptedCipher = try await encryptAndUpdateCipher(softDeletedCipher)
        try await cipherService.softDeleteCipherWithServer(id: id, encryptedCipher)
    }

    func updateCipher(_ cipherView: CipherView) async throws {
        let cipherEncryptionContext = try await clientService.vault().ciphers().encrypt(cipherView: cipherView)
        try await cipherService.updateCipherWithServer(
            cipherEncryptionContext.cipher,
            encryptedFor: cipherEncryptionContext.encryptedFor
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
        uri: String?
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>> {
        return switch mode {
        case .all:
            try await vaultListPublisher(
                filter: VaultListFilter(
                    addTOTPGroup: false,
                    addTrashGroup: false,
                    filterType: .allVaults,
                    group: group
                )
            )
        case .totp:
            try await vaultListPublisher(
                filter: VaultListFilter(
                    addTOTPGroup: false,
                    addTrashGroup: false,
                    group: .totp
                )
            )
        default:
            try await Publishers.CombineLatest(
                cipherService.ciphersPublisher(),
                availableFido2CredentialsPublisher
            )
            .asyncTryMap { ciphers, availableFido2Credentials in
                let decryptedCiphers = try await self.clientService.vault().ciphers()
                    .decryptListWithFailures(ciphers: ciphers).successes
                let matchingCiphers = await DefaultCipherMatchingHelper(
                    settingsService: self.settingsService,
                    stateService: self.stateService
                )
                .ciphersMatching(uri: uri, ciphers: decryptedCiphers)

                return try await self.createAutofillListSections(
                    availableFido2Credentials: availableFido2Credentials,
                    from: matchingCiphers,
                    mode: mode,
                    rpID: rpID,
                    searchText: nil
                )
            }
            .eraseToAnyPublisher()
            .values
        }
    }

    func organizationsPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[Organization], Error>> {
        try await organizationService.organizationsPublisher().eraseToAnyPublisher().values
    }

    func searchCipherAutofillPublisher(
        availableFido2CredentialsPublisher: AnyPublisher<[BitwardenSdk.CipherView]?, Error>,
        mode: AutofillListMode,
        filter: VaultListFilter,
        group: VaultListGroup? = nil,
        rpID: String?,
        searchText: String
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>> {
        try await Publishers.CombineLatest(
            searchPublisher(
                searchText: searchText,
                filter: filter,
                isActive: true
            ) { cipher in
                guard let group else {
                    return mode == .all || cipher.type.isLogin
                }
                return cipher.belongsToGroup(group)
            },
            availableFido2CredentialsPublisher
        )
        .asyncTryMap { ciphers, availableFido2Credentials in
            try await self.createAutofillListSections(
                availableFido2Credentials: availableFido2Credentials,
                from: ciphers,
                mode: mode,
                rpID: rpID,
                searchText: searchText
            )
        }
        .eraseToAnyPublisher()
        .values
    }

    func searchVaultListPublisher(
        searchText: String,
        group: VaultListGroup? = nil,
        filter: VaultListFilter
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListItem], Error>> {
        try await searchPublisher(
            searchText: searchText,
            filter: filter,
            isActive: group != .trash
        ) { cipher in
            guard let group else { return true }
            return cipher.belongsToGroup(group)
        }
        .asyncTryMap { ciphers in
            guard case .totp = group else {
                return ciphers.compactMap(VaultListItem.init)
            }
            return try await self.totpListItems(from: ciphers, filter: filter.filterType)
        }
        .eraseToAnyPublisher()
        .values
    }

    func vaultListPublisher(
        filter: VaultListFilter
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>> {
        try await vaultListDirectorStrategyFactory
            .make(filter: filter)
            .build(filter: filter)
    }

    // MARK: Private

    /// Creates the vault list sections from given ciphers and search text.
    /// This is to centralize sections creation from loading and searching.
    ///
    /// - Parameters:
    ///   - availableFido2Credentials: The available Fido2 credentials for Fido2 autofill list.
    ///   - from: The ciphers to create the sections, either load or search results.
    ///   - mode: The mode in which the autofill list is presented.
    ///   - rpID: The relying party identifier of the Fido2 request.
    ///   - searchText: The current search text.
    /// - Returns: The sections for the autofill list.
    private func createAutofillListSections( // swiftlint:disable:this function_body_length
        availableFido2Credentials: [CipherView]?,
        from ciphers: [CipherListView],
        mode: AutofillListMode,
        rpID: String?,
        searchText: String?
    ) async throws -> VaultListData {
        switch mode {
        case .all:
            guard !ciphers.isEmpty else {
                return VaultListData()
            }
            return VaultListData(sections: [
                VaultListSection(
                    id: "SearchResults",
                    items: ciphers.compactMap { .init(cipherListView: $0) },
                    name: ""
                ),
            ])
        case .combinedMultipleSections, .passwords:
            var sections = [VaultListSection]()
            if #available(iOSApplicationExtension 17.0, *),
               let fido2Section = try await loadAutofillFido2Section(
                   availableFido2Credentials: availableFido2Credentials,
                   mode: mode,
                   rpID: rpID,
                   searchText: searchText,
                   searchResults: searchText != nil ? ciphers : nil
               ) {
                sections.append(fido2Section)
            } else if ciphers.isEmpty {
                return VaultListData()
            }

            let sectionName = getAutofillPasswordsSectionName(
                mode: mode,
                rpID: rpID,
                searchText: searchText
            )

            sections.append(
                VaultListSection(
                    id: sectionName,
                    items: ciphers.compactMap { .init(cipherListView: $0) },
                    name: sectionName
                )
            )
            return VaultListData(sections: sections)
        case .combinedSingleSection:
            guard !ciphers.isEmpty else {
                return VaultListData()
            }

            let section = try await createAutofillListCombinedSingleSection(from: ciphers)
            return VaultListData(sections: [section])
        case .totp:
            let totpVaultListItems = try await totpListItems(from: ciphers, filter: .allVaults)
            guard !totpVaultListItems.isEmpty else {
                return VaultListData()
            }

            return VaultListData(sections: [
                VaultListSection(
                    id: "",
                    items: totpVaultListItems,
                    name: ""
                ),
            ])
        }
    }

    /// Creates the single vault list section for passwords + Fido2 credentials.
    /// - Parameter ciphers: Ciphers to load.
    /// - Returns: The section to display passwords + Fido2 credentials.
    private func createAutofillListCombinedSingleSection(
        from ciphers: [CipherListView]
    ) async throws -> VaultListSection {
        let vaultItems = try await ciphers
            .asyncMap { cipher in
                guard cipher.type.loginListView?.hasFido2 == true else {
                    return VaultListItem(cipherListView: cipher)
                }
                return try await createFido2VaultListItem(from: cipher)
            }
            .compactMap { $0 }

        return VaultListSection(
            id: Localizations.chooseALoginToSaveThisPasskeyTo,
            items: vaultItems,
            name: Localizations.chooseALoginToSaveThisPasskeyTo
        )
    }

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
        cipherView: CipherView
    ) async throws -> VaultListItem? {
        let decryptedFido2Credentials = try await clientService
            .platform()
            .fido2()
            .decryptFido2AutofillCredentials(cipherView: cipherView)

        guard let fido2CredentialAutofillView = decryptedFido2Credentials.first else {
            errorReporter.log(error: Fido2Error.decryptFido2AutofillCredentialsEmpty)
            return nil
        }

        return VaultListItem(
            cipherListView: cipherListView,
            fido2CredentialAutofillView: fido2CredentialAutofillView
        )
    }

    /// Gets the passwords vault list section name depending on the context.
    ///
    /// - Parameters:
    ///   - mode: The mode in which the autofill list is presented.
    ///   - rpID: The relying party identifier of the Fido2 request.
    ///   - searchText: The current search text.
    ///
    private func getAutofillPasswordsSectionName(
        mode: AutofillListMode,
        rpID: String?,
        searchText: String?
    ) -> String {
        guard mode != .passwords else {
            return ""
        }

        if let searchText {
            return Localizations.passwordsForX(searchText)
        }

        if let rpID {
            return Localizations.passwordsForX(rpID)
        }

        return Localizations.passwords
    }

    /// Loads the autofill Fido2 section if needed.
    /// - Parameters:
    ///   - availableFido2Credentials: The available Fido2 credentials for Fido2 autofill list.
    ///   - mode: The mode in which the autofill list is presented.
    ///   - rpID: The relying party identifier of the Fido2 request.
    ///   - searchText: The current search text.
    ///   - searchResults: The search results.
    /// - Returns: The vault list section for Fido2 autofill if needed.
    private func loadAutofillFido2Section(
        availableFido2Credentials: [CipherView]?,
        mode: AutofillListMode,
        rpID: String?,
        searchText: String? = nil,
        searchResults: [CipherListView]? = nil
    ) async throws -> VaultListSection? {
        guard let fido2Credentials = availableFido2Credentials,
              !fido2Credentials.isEmpty,
              case .combinedMultipleSections = mode,
              let rpID else {
            return nil
        }

        var filteredFido2Credentials = fido2Credentials
        if let searchResults {
            filteredFido2Credentials = filteredFido2Credentials.filter { cipher in
                searchResults.contains(where: { $0.id == cipher.id })
            }
        }

        guard !filteredFido2Credentials.isEmpty else {
            return nil
        }

        let fido2ListItems: [VaultListItem?] = try await filteredFido2Credentials
            .asyncMap { cipher in
                try await createFido2VaultListItem(from: cipher)
            }

        return VaultListSection(
            id: Localizations.passkeysForX(searchText ?? rpID),
            items: fido2ListItems.compactMap { $0 },
            name: Localizations.passkeysForX(searchText ?? rpID)
        )
    }
}

// MARK: - CipherListView

private extension CipherListView {
    /// Whether the cipher belongs to a group.
    /// - Parameter group: The group to filter.
    /// - Returns: `true` if the cipher belongs to the group, `false` otherwise.
    func belongsToGroup(_ group: VaultListGroup) -> Bool {
        return switch group {
        case .card:
            type.isCard
        case let .collection(id, _, _):
            collectionIds.contains(id)
        case let .folder(id, _):
            folderId == id
        case .identity:
            type == .identity
        case .login:
            type.isLogin
        case .noFolder:
            folderId == nil
        case .secureNote:
            type == .secureNote
        case .sshKey:
            type == .sshKey
        case .totp:
            type.loginListView?.totp != nil
        case .trash:
            deletedDate != nil
        }
    }
}

// MARK: - VaultListFilter

/// The filter to be used when getting the vault list.
public struct VaultListFilter: Sendable {
    /// Whether to add the TOTP group.
    let addTOTPGroup: Bool

    /// Whether to add the trash group.
    let addTrashGroup: Bool

    /// The vault filter type.
    let filterType: VaultFilterType

    /// The vault list group to filter.
    let group: VaultListGroup?

    /// The mode in which the autofill list is presented.
    let mode: AutofillListMode?

    /// The relying party identifier of the Fido2 request.
    let rpID: String?

    /// The URI used to filter ciphers that have a matching URI.
    let uri: String?

    /// Initializes the filter.
    /// - Parameters:
    ///   - addTOTPGroup: Whether to add the TOTP group.
    ///   - addTrashGroup: Whether to add the trash group.
    ///   - filterType: The vault filter type.
    ///   - group: The vault list group to filter.
    ///   - mode: The mode in which the autofill list is presented.
    ///   - rpID: The relying party identifier of the Fido2 request.
    ///   - uri: The URI used to filter ciphers that have a matching URI
    init(
        addTOTPGroup: Bool = true,
        addTrashGroup: Bool = true,
        filterType: VaultFilterType = .allVaults,
        group: VaultListGroup? = nil,
        mode: AutofillListMode? = nil,
        rpID: String? = nil,
        uri: String? = nil
    ) {
        self.addTOTPGroup = addTOTPGroup
        self.addTrashGroup = addTrashGroup
        self.filterType = filterType
        self.group = group
        self.mode = mode
        self.rpID = rpID
        self.uri = uri
    }
} // swiftlint:disable:this file_length
