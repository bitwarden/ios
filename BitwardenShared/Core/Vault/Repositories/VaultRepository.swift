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
    ///   - isRefresh: Whether the sync is being performed as a manual refresh.
    ///   - filter: The filter to apply to the vault.
    /// - Returns: If a sync is performed without error, this returns `[VaultListSection]` to display.
    ///
    @discardableResult
    func fetchSync(isManualRefresh: Bool, filter: VaultFilterType) async throws -> [VaultListSection]?

    // MARK: Data Methods

    /// Adds a cipher to the user's vault.
    ///
    /// - Parameter cipher: The cipher that the user is added.
    ///
    func addCipher(_ cipher: CipherView) async throws

    /// Removes any temporarily downloaded attachments.
    func clearTemporaryDownloads()

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
    func doesActiveAccountHavePremium() async throws -> Bool

    /// Download and decrypt an attachment and save the file to local storage on the device.
    ///
    /// - Parameters:
    ///   - attachment: The attachment to download.
    ///   - cipher: The cipher the attachment belongs to.
    ///
    /// - Returns: The url of the temporary location of downloaded and decrypted data on the user's device.
    ///
    func downloadAttachment(_ attachment: AttachmentView, cipher: CipherView) async throws -> URL?

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

    /// Fetches the folders that are available to the user.
    ///
    /// - Returns: The folders that are available to the user.
    ///
    func fetchFolders() async throws -> [FolderView]

    /// Get the value of the disable auto-copy TOTP setting for the current user.
    ///
    func getDisableAutoTotpCopy() async throws -> Bool

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

    /// Removes an account id.
    ///
    ///  - Parameter userId: An optional userId. Defaults to the active user id.
    ///
    func remove(userId: String?) async

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
    /// - Parameter cipher: The cipher to share.
    ///
    func shareCipher(_ cipher: CipherView) async throws

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
    /// - Parameter uri: The URI used to filter ciphers that have a matching URI.
    /// - Returns: The list of a user's ciphers that can be used for autofill.
    ///
    func ciphersAutofillPublisher(
        uri: String?
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[CipherView], Error>>

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
    ///     - searchText:  The search text to filter the cipher list.
    ///     - filterType: The vault filter type to apply to the cipher list.
    /// - Returns: A publisher for searching the user's ciphers for autofill.
    ///
    func searchCipherAutofillPublisher(
        searchText: String,
        filterType: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[CipherView], Error>>

    /// A publisher for searching a user's cipher objects based on the specified search text and filter type.
    ///
    /// - Parameters:
    ///     - searchText:  The search text to filter the cipher list.
    ///     - group: The group to search. Searches all groups if nil.
    ///     - filterType: The vault filter type to apply to the cipher list.
    /// - Returns: A publisher searching for the user's ciphers.
    ///
    func searchVaultListPublisher(
        searchText: String,
        group: VaultListGroup?,
        filterType: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListItem], Error>>

    /// A publisher for the vault list which returns a list of sections and items that are
    /// displayed in the vault.
    ///
    /// - Parameter filter: A filter to apply to the vault items.
    /// - Returns: A publisher for the sections of the vault list which will be notified as the
    ///     data changes.
    ///
    func vaultListPublisher(
        filter: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListSection], Error>>

    /// A publisher for the sections within a group of items in the vault list.
    ///
    /// - Parameters:
    ///   - group: The group of items within the vault list to subscribe to.
    ///   - filter: A filter to apply to the vault items.
    /// - Returns: A publisher for the sections within a group of items in the vault list which will
    ///     be notified as the data changes.
    ///
    func vaultListPublisher(
        group: VaultListGroup,
        filter: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListSection], Error>>
}

extension VaultRepository {
    /// A publisher for searching a user's cipher objects based on the specified search text and filter type.
    ///
    /// - Parameters:
    ///     - searchText:  The search text to filter the cipher list.
    ///     - filterType: The vault filter type to apply to the cipher list.
    /// - Returns: A publisher searching for the user's ciphers.
    ///
    func searchVaultListPublisher(
        searchText: String,
        filterType: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListItem], Error>> {
        try await searchVaultListPublisher(
            searchText: searchText,
            group: nil,
            filterType: filterType
        )
    }
}

/// A default implementation of a `VaultRepository`.
///
class DefaultVaultRepository { // swiftlint:disable:this type_body_length
    // MARK: Properties

    /// The API service used to perform API requests for the ciphers in a user's vault.
    private let cipherAPIService: CipherAPIService

    /// The service used to manage syncing and updates to the user's ciphers.
    private let cipherService: CipherService

    private let clientService: ClientService

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

    /// The service used by the application to manage user settings.
    let settingsService: SettingsService

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The service used to handle syncing vault data with the API.
    private let syncService: SyncService

    /// The service used to get the present time.
    private let timeProvider: TimeProvider

    /// The service used by the application to manage vault access.
    private let vaultTimeoutService: VaultTimeoutService

    // MARK: Initialization

    /// Initialize a `DefaultVaultRepository`.
    ///
    /// - Parameters:
    ///   - cipherAPIService: The API service used to perform API requests for the ciphers in a user's vault.
    ///   - cipherService: The service used to manage syncing and updates to the user's ciphers.
    ///   - clientAuth: The client used by the application to handle auth related encryption and decryption tasks.
    ///   - clientCrypto: The client used by the application to handle encryption and decryption setup tasks.
    ///   - clientVault: The client used by the application to handle vault encryption and decryption tasks.
    ///   - collectionService: The service for managing the collections for the user.
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - folderService: The service used to manage syncing and updates to the user's folders.
    ///   - organizationService: The service used to manage syncing and updates to the user's organizations.
    ///   - settingsService: The service used by the application to manage user settings.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///   - timeProvider: The service used to get the present time.
    ///   - vaultTimeoutService: The service used by the application to manage vault access.
    ///
    init(
        cipherAPIService: CipherAPIService,
        cipherService: CipherService,
        clientService: ClientService,
        collectionService: CollectionService,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        folderService: FolderService,
        organizationService: OrganizationService,
        settingsService: SettingsService,
        stateService: StateService,
        syncService: SyncService,
        timeProvider: TimeProvider,
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.cipherAPIService = cipherAPIService
        self.cipherService = cipherService
        self.clientService = clientService
        self.collectionService = collectionService
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.folderService = folderService
        self.organizationService = organizationService
        self.settingsService = settingsService
        self.stateService = stateService
        self.syncService = syncService
        self.timeProvider = timeProvider
        self.vaultTimeoutService = vaultTimeoutService
    }

    // MARK: Private

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
        activeCiphers: [CipherView],
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
    ///   - searchText:  The search text to filter the cipher list.
    ///   - filterType: The vault filter type to apply to the cipher list.
    ///   - cipherFilter: An optional additional filter to apply to the cipher list.
    /// - Returns: A publisher searching for the user's ciphers.
    ///
    private func searchPublisher(
        searchText: String,
        filterType: VaultFilterType,
        isActive: Bool,
        cipherFilter: ((CipherView) -> Bool)? = nil
    ) async throws -> AnyPublisher<[CipherView], Error> {
        let userId = try await stateService.getActiveAccountId()

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        let isMatchingCipher: (CipherView) -> Bool = isActive
            ? { $0.deletedDate == nil }
            : { $0.deletedDate != nil }

        return try await cipherService.ciphersPublisher().asyncTryMap { ciphers -> [CipherView] in
            // Convert the Ciphers to CipherViews and filter appropriately.
            let matchingCiphers = try await ciphers.asyncMap { cipher in
                try await self.clientService.clientVault(for: userId).ciphers().decrypt(cipher: cipher)
            }
            .filter { cipher in
                filterType.cipherFilter(cipher) &&
                    isMatchingCipher(cipher) &&
                    (cipherFilter?(cipher) ?? true)
            }

            var matchedCiphers: [CipherView] = []
            var lowPriorityMatchedCiphers: [CipherView] = []

            // Search the ciphers.
            matchingCiphers.forEach { cipherView in
                if cipherView.name.lowercased()
                    .folding(options: .diacriticInsensitive, locale: nil).contains(query) {
                    matchedCiphers.append(cipherView)
                } else if query.count >= 8, cipherView.id?.starts(with: query) == true {
                    lowPriorityMatchedCiphers.append(cipherView)
                } else if cipherView.subtitle?.lowercased()
                    .folding(options: .diacriticInsensitive, locale: nil).contains(query) == true {
                    lowPriorityMatchedCiphers.append(cipherView)
                } else if cipherView.login?.uris?.contains(where: { $0.uri?.contains(query) == true }) == true {
                    lowPriorityMatchedCiphers.append(cipherView)
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
        from ciphers: [CipherView],
        filter: VaultFilterType?
    ) async throws -> [VaultListItem] {
        // Ensure the user has premium features access
        let hasPremiumFeaturesAccess = await (try? doesActiveAccountHavePremium()) ?? false
        guard hasPremiumFeaturesAccess else {
            return []
        }

        // Filter and sort the list.
        let activeCiphers = ciphers
            .filter(filter?.cipherFilter(_:) ?? { _ in true })
            .filter { cipher in
                cipher.deletedDate == nil
                    && cipher.type == .login
                    && cipher.login?.totp != nil
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        // Convert the CipherViews into VaultListItem.
        let totpItems: [VaultListItem] = try await activeCiphers
            .asyncMap { try await totpItem(for: $0) }
            .compactMap { $0 }

        return totpItems
    }

    /// A transform to convert a `CipherView` into a TOTP `VaultListItem`.
    ///
    /// - Parameter cipherView: The cipher view that may have a TOTP key.
    /// - Returns: A `VaultListItem` if the CipherView supports TOTP.
    ///
    private func totpItem(for cipherView: CipherView) async throws -> VaultListItem? {
        let userId = try await stateService.getActiveAccountId()

        guard let id = cipherView.id,
              let login = cipherView.login,
              let key = login.totp else {
            return nil
        }
        guard let code = try? await clientService.clientVault(for: userId).generateTOTPCode(
            for: key,
            date: timeProvider.presentTime
        ) else {
            errorReporter.log(
                error: TOTPServiceError
                    .unableToGenerateCode("Unable to create TOTP code for key \(key) for cipher id \(id)")
            )
            return nil
        }

        let listModel = VaultListTOTP(
            id: id,
            loginView: login,
            totpCode: code
        )
        return VaultListItem(
            id: id,
            itemType: .totp(
                name: cipherView.name,
                totpModel: listModel
            )
        )
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
        activeCiphers: [CipherView],
        group: VaultListGroup,
        filter: VaultFilterType,
        folders: [Folder]
    ) async throws -> VaultListSection? {
        let userId = try await stateService.getActiveAccountId()

        guard let folderId = group.folderId else { return nil }

        let folders = try await clientService.clientVault(for: userId).folders()
            .decryptList(folders: folders)
            .filter(filter.folderFilter)
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
        filter: VaultFilterType,
        ciphers: [Cipher],
        folders: [Folder] = []
    ) async throws -> [VaultListSection] {
        let userId = try await stateService.getActiveAccountId()

        let ciphers = try await ciphers.asyncMap { cipher in
            try await self.clientService.clientVault(for: userId).ciphers().decrypt(cipher: cipher)
        }
        .filter(filter.cipherFilter)
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let activeCiphers = ciphers.filter { $0.deletedDate == nil }
        let deletedCiphers = ciphers.filter { $0.deletedDate != nil }

        let items: [VaultListItem]
        switch group {
        case .card:
            items = activeCiphers.filter { $0.type == .card }.compactMap(VaultListItem.init)
        case let .collection(id, _, _):
            items = activeCiphers.filter { $0.collectionIds.contains(id) }.compactMap(VaultListItem.init)
        case let .folder(id, _):
            items = activeCiphers.filter { $0.folderId == id }.compactMap(VaultListItem.init)
        case .identity:
            items = activeCiphers.filter { $0.type == .identity }.compactMap(VaultListItem.init)
        case .login:
            items = activeCiphers.filter { $0.type == .login }.compactMap(VaultListItem.init)
        case .noFolder:
            items = activeCiphers.filter { $0.folderId == nil }.compactMap(VaultListItem.init)
        case .secureNote:
            items = activeCiphers.filter { $0.type == .secureNote }.compactMap(VaultListItem.init)
        case .totp:
            // Ensure the user has premium features access
            guard try await doesActiveAccountHavePremium() else {
                items = []
                break
            }
            items = try await totpListItems(from: ciphers, filter: filter)
        case .trash:
            items = deletedCiphers.compactMap(VaultListItem.init)
        }

        let folderSection = try await vaultListFolderSection(
            activeCiphers: activeCiphers,
            group: group,
            filter: filter,
            folders: folders
        )

        return [
            folderSection,
            VaultListSection(id: "Items", items: items, name: Localizations.items),
        ]
        .compactMap { $0 }
        .filter { !$0.items.isEmpty }
    }

    /// Returns a list of the sections in the vault list from a sync response.
    ///
    /// - Parameters:
    ///   - ciphers: The ciphers used to build the list of sections.
    ///   - collections: The collections used to build the list of sections.
    ///   - folders: The folders used to build the list of sections.
    ///   - filter: A filter to apply to the vault items.
    /// - Returns: A list of the sections to display in the vault list.
    ///
    private func vaultListSections( // swiftlint:disable:this function_body_length
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultFilterType
    ) async throws -> [VaultListSection] {
        let userId = try await stateService.getActiveAccountId()

        let ciphers = try await ciphers.asyncMap { cipher in
            try await self.clientService.clientVault(for: userId).ciphers().decrypt(cipher: cipher)
        }
        .filter(filter.cipherFilter)
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let folders = try await clientService.clientVault(for: userId).folders()
            .decryptList(folders: folders)
            .filter(filter.folderFilter)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let collections = try await clientService.clientVault(for: userId).collections()
            .decryptList(collections: collections)
            .filter(filter.collectionFilter)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        guard !ciphers.isEmpty else { return [] }

        let activeCiphers = ciphers.filter { $0.deletedDate == nil }

        let ciphersFavorites = activeCiphers.filter(\.favorite).compactMap(VaultListItem.init)
        let ciphersNoFolder = activeCiphers.filter { $0.folderId == nil }.compactMap(VaultListItem.init)

        let ciphersTrashCount = ciphers.lazy.filter { $0.deletedDate != nil }.count
        let ciphersTrashItem = VaultListItem(id: "Trash", itemType: .group(.trash, ciphersTrashCount))

        let showNoFolderCipherGroup = collections.isEmpty && ciphersNoFolder.count < Constants.noFolderListSize

        // Add TOTP items for premium accounts.
        var totpItems = [VaultListItem]()
        if try await doesActiveAccountHavePremium() {
            let oneTimePasswordCount: Int = try await totpListItems(from: ciphers, filter: filter).count

            totpItems = (oneTimePasswordCount > 0) ? [
                VaultListItem(
                    id: "Types.VerificationCodes",
                    itemType: .group(
                        .totp,
                        oneTimePasswordCount
                    )
                ),
            ] : []
        }

        var folderItems = folderVaultListItems(
            activeCiphers: activeCiphers,
            folderTree: folders.asNestedNodes()
        )

        // Add no folder to folders item if needed.
        if !showNoFolderCipherGroup {
            folderItems.append(
                VaultListItem(
                    id: "NoFolderFolderItem",
                    itemType: .group(.noFolder, ciphersNoFolder.count)
                )
            )
        }

        let collectionItems: [VaultListItem] = collections.compactMap { collection in
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
                    .collection(id: collectionId, name: collection.name, organizationId: collection.organizationId),
                    collectionCount
                )
            )
        }

        let typesCardCount = activeCiphers.lazy.filter { $0.type == .card }.count
        let typesIdentityCount = activeCiphers.lazy.filter { $0.type == .identity }.count
        let typesLoginCount = activeCiphers.lazy.filter { $0.type == .login }.count
        let typesSecureNoteCount = activeCiphers.lazy.filter { $0.type == .secureNote }.count

        let types = [
            VaultListItem(id: "Types.Logins", itemType: .group(.login, typesLoginCount)),
            VaultListItem(id: "Types.Cards", itemType: .group(.card, typesCardCount)),
            VaultListItem(id: "Types.Identities", itemType: .group(.identity, typesIdentityCount)),
            VaultListItem(id: "Types.SecureNotes", itemType: .group(.secureNote, typesSecureNoteCount)),
        ]

        return [
            VaultListSection(id: "TOTP", items: totpItems, name: Localizations.totp),
            VaultListSection(id: "Favorites", items: ciphersFavorites, name: Localizations.favorites),
            VaultListSection(id: "Types", items: types, name: Localizations.types),
            VaultListSection(id: "Folders", items: folderItems, name: Localizations.folders),
            VaultListSection(
                id: "NoFolder",
                items: showNoFolderCipherGroup ? ciphersNoFolder : [],
                name: Localizations.folderNone
            ),
            VaultListSection(id: "Collections", items: collectionItems, name: Localizations.collections),
            VaultListSection(id: "Trash", items: [ciphersTrashItem], name: Localizations.trash),
        ].filter { !$0.items.isEmpty }
    }
}

extension DefaultVaultRepository: VaultRepository {
    // MARK: API Methods

    @discardableResult
    func fetchSync(isManualRefresh: Bool, filter: VaultFilterType) async throws -> [VaultListSection]? {
        let allowSyncOnRefresh = try await stateService.getAllowSyncOnRefresh()
        guard !isManualRefresh || allowSyncOnRefresh else { return nil }
        try await syncService.fetchSync(forceSync: isManualRefresh)
        let ciphers = try await cipherService.fetchAllCiphers()
        let collections = try await collectionService.fetchAllCollections(includeReadOnly: true)
        let folders = try await folderService.fetchAllFolders()
        return try await vaultListSections(
            from: ciphers,
            collections: collections,
            folders: folders,
            filter: filter
        )
    }

    // MARK: Data Methods

    func addCipher(_ cipher: CipherView) async throws {
        let userId = try await stateService.getActiveAccountId()
        let cipher = try await clientService.clientVault(for: userId).ciphers().encrypt(cipherView: cipher)
        try await cipherService.addCipherWithServer(cipher)
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

    func fetchCipher(withId id: String) async throws -> CipherView? {
        let userId = try await stateService.getActiveAccountId()

        guard let cipher = try await cipherService.fetchCipher(withId: id) else { return nil }
        return try? await clientService.clientVault(for: userId).ciphers().decrypt(cipher: cipher)
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
        let userId = try await stateService.getActiveAccountId()

        let collections = try await collectionService.fetchAllCollections(includeReadOnly: includeReadOnly)
        return try await clientService.clientVault(for: userId).collections()
            .decryptList(collections: collections)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func deleteCipher(_ id: String) async throws {
        try await cipherService.deleteCipherWithServer(id: id)
    }

    func fetchFolders() async throws -> [FolderView] {
        let userId = try await stateService.getActiveAccountId()

        let folders = try await folderService.fetchAllFolders()
        return try await clientService.clientVault(for: userId).folders()
            .decryptList(folders: folders)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func deleteAttachment(withId attachmentId: String, cipherId: String) async throws -> CipherView? {
        let userId = try await stateService.getActiveAccountId()

        // Delete the attachment and then decrypt the resulting updated cipher.
        if let updatedCipher = try await cipherService.deleteAttachmentWithServer(
            attachmentId: attachmentId,
            cipherId: cipherId
        ) {
            return try await clientService.clientVault(for: userId).ciphers().decrypt(cipher: updatedCipher)
        }
        // This would only return nil if the cipher somehow doesn't exist in the datastore anymore.
        return nil
    }

    func doesActiveAccountHavePremium() async throws -> Bool {
        // Check if the user has a premium account personally.
        let account = try await stateService.getActiveAccount()
        let hasPremiumPersonally = account.profile.hasPremiumPersonally ?? false
        guard !hasPremiumPersonally else {
            return true
        }

        // If not, check if any of their organizations grant them premium access.
        let organizations = try await organizationService
            .fetchAllOrganizations()
            .filter { $0.enabled && $0.usersGetPremium }
        return !organizations.isEmpty
    }

    func downloadAttachment(_ attachment: AttachmentView, cipher: CipherView) async throws -> URL? {
        let userId = try await stateService.getActiveAccountId()

        guard let attachmentId = attachment.id,
              let attachmentName = attachment.fileName,
              let cipherId = cipher.id
        else { throw BitwardenError.dataError("Missing data") }

        // Get the encrypted cipher and attachment, then download the actual data of the attachment.
        let encryptedCipher = try await clientService.clientVault(for: userId).ciphers().encrypt(cipherView: cipher)
        guard let attachment = encryptedCipher.attachments?.first(where: { $0.id == attachmentId }),
              let downloadedUrl = try await cipherService.downloadAttachment(withId: attachmentId, cipherId: cipherId)
        else { return nil }

        // Create a temporary location to write the decrypted data to.
        let storageUrl = try FileManager.default.attachmentsUrl(for: userId)

        try FileManager.default.createDirectory(at: storageUrl, withIntermediateDirectories: true)
        let temporaryUrl = storageUrl.appendingPathComponent(attachmentName)

        // Decrypt the downloaded data and move it to the specified temporary location.
        try await clientService.clientVault(for: userId).attachments().decryptFile(
            cipher: encryptedCipher,
            attachment: attachment,
            encryptedFilePath: downloadedUrl.path,
            decryptedFilePath: temporaryUrl.path
        )

        // Remove the encrypted file.
        try FileManager.default.removeItem(at: downloadedUrl)

        // Return the temporary location where the downloaded data is located.
        return temporaryUrl
    }

    func getDisableAutoTotpCopy() async throws -> Bool {
        try await stateService.getDisableAutoTotpCopy()
    }

    func needsSync() async throws -> Bool {
        let userId = try await stateService.getActiveAccountId()
        return try await syncService.needsSync(for: userId)
    }

    func refreshTOTPCode(for key: TOTPKeyModel) async throws -> LoginTOTPState {
        let userId = try await stateService.getActiveAccountId()

        let codeState = try await clientService.clientVault(for: userId).generateTOTPCode(
            for: key.rawAuthenticatorKey,
            date: timeProvider.presentTime
        )
        return LoginTOTPState(
            authKeyModel: key,
            codeModel: codeState
        )
    }

    func refreshTOTPCodes(for items: [VaultListItem]) async throws -> [VaultListItem] {
        let userId = try await stateService.getActiveAccountId()

        return await items.asyncMap { item in
            guard case let .totp(name, model) = item.itemType,
                  let key = model.loginView.totp,
                  let code = try? await clientService.clientVault(for: userId).generateTOTPCode(for: key, date: timeProvider.presentTime)
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
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func remove(userId: String?) async {
        await vaultTimeoutService.remove(userId: userId)
    }

    func restoreCipher(_ cipher: BitwardenSdk.CipherView) async throws {
        let userId = try await stateService.getActiveAccountId()
        guard let id = cipher.id else { throw CipherAPIServiceError.updateMissingId }
        let restoredCipher = cipher.update(deletedDate: nil)
        let encryptCipher = try await clientService.clientVault(for: userId)
            .ciphers().encrypt(cipherView: restoredCipher)
        try await cipherService.restoreCipherWithServer(id: id, encryptCipher)
    }

    func saveAttachment(cipherView: CipherView, fileData: Data, fileName: String) async throws -> CipherView {
        let userId = try await stateService.getActiveAccountId()

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
        let cipher = try await clientService.clientVault(for: userId).ciphers().encrypt(cipherView: cipherView)
        let attachment = try await clientService.clientVault(for: userId).attachments().encryptBuffer(
            cipher: cipher,
            attachment: attachmentView,
            buffer: fileData
        )

        // Save the attachment to the cipher and return the updated cipher.
        let updatedCipher = try await cipherService.saveAttachmentWithServer(
            cipher: cipher,
            attachment: attachment
        )
        return try await clientService.clientVault(for: userId).ciphers().decrypt(cipher: updatedCipher)
    }

    func shareCipher(_ cipher: CipherView) async throws {
        let userId = try await stateService.getActiveAccountId()
        let encryptedCipher = try await clientService.clientVault(for: userId).ciphers().encrypt(cipherView: cipher)
        try await cipherService.shareCipherWithServer(encryptedCipher)
    }

    func softDeleteCipher(_ cipher: CipherView) async throws {
        let userId = try await stateService.getActiveAccountId()
        guard let id = cipher.id else { throw CipherAPIServiceError.updateMissingId }
        let softDeletedCipher = cipher.update(deletedDate: timeProvider.presentTime)
        let encryptCipher = try await clientService.clientVault(for: userId)
            .ciphers().encrypt(cipherView: softDeletedCipher)
        try await cipherService.softDeleteCipherWithServer(id: id, encryptCipher)
    }

    func updateCipher(_ cipherView: CipherView) async throws {
        let userId = try await stateService.getActiveAccountId()
        let cipher = try await clientService.clientVault(for: userId).ciphers().encrypt(cipherView: cipherView)
        try await cipherService.updateCipherWithServer(cipher)
    }

    func updateCipherCollections(_ cipherView: CipherView) async throws {
        let userId = try await stateService.getActiveAccountId()
        let cipher = try await clientService.clientVault(for: userId).ciphers().encrypt(cipherView: cipherView)
        try await cipherService.updateCipherCollectionsWithServer(cipher)
    }

    // MARK: Publishers

    func cipherPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[CipherListView], Error>> {
        let userId = try await stateService.getActiveAccountId()
        return try await cipherService.ciphersPublisher()
            .asyncTryMap { ciphers in
                try await self.clientService.clientVault(for: userId).ciphers().decryptList(ciphers: ciphers)
                    .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            }
            .eraseToAnyPublisher()
            .values
    }

    func cipherDetailsPublisher(id: String) async throws -> AsyncThrowingPublisher<AnyPublisher<CipherView?, Error>> {
        let userId = try await stateService.getActiveAccountId()
        return try await cipherService.ciphersPublisher()
            .asyncTryMap { ciphers -> CipherView? in
                guard let cipher = ciphers.first(where: { $0.id == id }) else { return nil }
                return try await self.clientService.clientVault(for: userId).ciphers().decrypt(cipher: cipher)
            }
            .eraseToAnyPublisher()
            .values
    }

    func ciphersAutofillPublisher(
        uri: String?
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[CipherView], Error>> {
        let userId = try await stateService.getActiveAccountId()

        return try await cipherService.ciphersPublisher()
            .asyncTryMap { ciphers in
                try await ciphers.asyncMap { cipher in
                    try await self.clientService.clientVault(for: userId).ciphers().decrypt(cipher: cipher)
                }
            }
            .asyncTryMap { ciphers in
                await CipherMatchingHelper(
                    settingsService: self.settingsService,
                    stateService: self.stateService
                )
                .ciphersMatching(uri: uri, ciphers: ciphers)
            }
            .eraseToAnyPublisher()
            .values
    }

    func organizationsPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[Organization], Error>> {
        try await organizationService.organizationsPublisher().eraseToAnyPublisher().values
    }

    func searchCipherAutofillPublisher(
        searchText: String,
        filterType: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[CipherView], Error>> {
        try await searchPublisher(
            searchText: searchText,
            filterType: filterType,
            isActive: true
        ) { cipher in
            cipher.type == .login
        }
        .eraseToAnyPublisher()
        .values
    }

    func searchVaultListPublisher(
        searchText: String,
        group: VaultListGroup?,
        filterType: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListItem], Error>> {
        try await searchPublisher(
            searchText: searchText,
            filterType: filterType,
            isActive: group != .trash
        ) { cipher in
            guard let group else { return true }
            switch group {
            case .card:
                return cipher.type == .card
            case let .collection(id, _, _):
                return cipher.collectionIds.contains(id)
            case let .folder(id, _):
                return cipher.folderId == id
            case .identity:
                return cipher.type == .identity
            case .login:
                return cipher.type == .login
            case .noFolder:
                return cipher.folderId == nil
            case .secureNote:
                return cipher.type == .secureNote
            case .totp:
                return cipher.type == .login
                    && TOTPKey(cipher.login?.totp ?? "") != nil
            case .trash:
                return cipher.deletedDate != nil
            }
        }
        .asyncTryMap { ciphers in
            guard case .totp = group else {
                return ciphers.compactMap(VaultListItem.init)
            }
            return try await self.totpListItems(from: ciphers, filter: filterType)
        }
        .eraseToAnyPublisher()
        .values
    }

    func vaultListPublisher(
        filter: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListSection], Error>> {
        try await Publishers.CombineLatest3(
            cipherService.ciphersPublisher(),
            collectionService.collectionsPublisher(),
            folderService.foldersPublisher()
        )
        .asyncTryMap { ciphers, collections, folders in
            try await self.vaultListSections(from: ciphers, collections: collections, folders: folders, filter: filter)
        }
        .eraseToAnyPublisher()
        .values
    }

    func vaultListPublisher(
        group: VaultListGroup,
        filter: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListSection], Error>> {
        try await Publishers.CombineLatest(
            cipherService.ciphersPublisher(),
            folderService.foldersPublisher()
        )
        .asyncTryMap { ciphers, folders in
            try await self.vaultListItems(group: group, filter: filter, ciphers: ciphers, folders: folders)
        }
        .eraseToAnyPublisher()
        .values
    }
} // swiftlint:disable:this file_length
