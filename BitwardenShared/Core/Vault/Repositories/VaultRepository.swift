import BitwardenSdk
import Combine
import Foundation

/// A protocol for a `VaultRepository` which manages access to the data needed by the UI layer.
///
protocol VaultRepository: AnyObject {
    // MARK: API Methods

    /// Performs an API request to sync the user's vault data. The publishers in the repository can
    /// be used to subscribe to the vault data, which are updated as a result of the request.
    ///
    /// - Parameter isRefresh: Whether the sync is being performed as a manual refresh.
    ///
    func fetchSync(isManualRefresh: Bool) async throws

    // MARK: Data Methods

    /// Adds a cipher to the user's vault.
    ///
    /// - Parameter cipher: The cipher that the user is added.
    ///
    func addCipher(_ cipher: CipherView) async throws

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

    /// A publisher for a user's cipher objects based on the specified search text and filter type.
    ///
    /// - Parameters:
    ///     - searchText:  The search text to filter the cipher list.
    ///     - filterType: The vault filter type to apply to the cipher list.
    /// - Returns: A publisher for the user's ciphers.
    func searchCipherPublisher(
        searchText: String,
        filterType: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListItem], Error>>

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

    /// Validates the user's entered master password to determine if it matches the stored hash.
    ///
    /// - Parameter password: The user's master password.
    /// - Returns: Whether the hash of the password matches the stored hash.
    ///
    func validatePassword(_ password: String) async throws -> Bool

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

    /// A publisher for the list of organizations the user is a member of.
    ///
    /// - Returns: A publisher for the list of organizations the user is a member of.
    ///
    func organizationsPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[Organization], Error>>

    /// Updates the list of collections for a cipher in the user's vault.
    ///
    /// - Parameter cipher: The cipher that the user is updating.
    ///
    func updateCipherCollections(_ cipher: CipherView) async throws

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

    /// A publisher for a group of items within the vault list.
    ///
    /// - Parameters:
    ///   - group: The group of items within the vault list to subscribe to.
    ///   - filter: A filter to apply to the vault items.
    /// - Returns: A publisher for a group of items within the vault list which will be notified as
    ///     the data changes.
    ///
    func vaultListPublisher(
        group: VaultListGroup,
        filter: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListItem], Error>>
}

/// A default implementation of a `VaultRepository`.
///
class DefaultVaultRepository {
    // MARK: Properties

    /// The API service used to perform API requests for the ciphers in a user's vault.
    private let cipherAPIService: CipherAPIService

    /// The service used to manage syncing and updates to the user's ciphers.
    private let cipherService: CipherService

    /// The client used by the application to handle auth related encryption and decryption tasks.
    private let clientAuth: ClientAuthProtocol

    /// The client used by the application to handle encryption and decryption setup tasks.
    private let clientCrypto: ClientCryptoProtocol

    /// The client used by the application to handle vault encryption and decryption tasks.
    private let clientVault: ClientVaultService

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

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The service used to handle syncing vault data with the API.
    private let syncService: SyncService

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
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///   - vaultTimeoutService: The service used by the application to manage vault access.
    ///
    init(
        cipherAPIService: CipherAPIService,
        cipherService: CipherService,
        clientAuth: ClientAuthProtocol,
        clientCrypto: ClientCryptoProtocol,
        clientVault: ClientVaultService,
        collectionService: CollectionService,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        folderService: FolderService,
        organizationService: OrganizationService,
        stateService: StateService,
        syncService: SyncService,
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.cipherAPIService = cipherAPIService
        self.cipherService = cipherService
        self.clientAuth = clientAuth
        self.clientCrypto = clientCrypto
        self.clientVault = clientVault
        self.collectionService = collectionService
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.folderService = folderService
        self.organizationService = organizationService
        self.stateService = stateService
        self.syncService = syncService
        self.vaultTimeoutService = vaultTimeoutService
    }

    // MARK: Private

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
        // Filter and sort the list.
        let activeCiphers = ciphers
            .filter(filter?.cipherFilter(_:) ?? { _ in true })
            .filter { cipher in
                cipher.deletedDate == nil
                    && cipher.type == .login
                    && cipher.login?.totp != nil
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        // A transform to convert a `CipherListView` into a `VaultListItem`.
        let listItemTransform: (CipherView) async throws -> VaultListItem? = { [weak self] cipherView in
            guard let self,
                  let id = cipherView.id,
                  let login = cipherView.login,
                  let key = login.totp else {
                return nil
            }

            let code = try await clientVault.generateTOTPCode(
                for: key,
                date: Date()
            )
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

        // Convert the CipherViews into VaultListItem.
        let totpItems: [VaultListItem] = try await activeCiphers
            .asyncMap(listItemTransform)
            .compactMap { $0 }

        return totpItems
    }

    /// Returns a list of items that are grouped together in the vault list from a list of encrypted ciphers.
    ///
    /// - Parameters:
    ///   - group: The group of items to get.
    ///   - filter: A filter to apply to the vault items.
    ///   - ciphers: The ciphers to build the list of items.
    /// - Returns: A list of items for the group in the vault list.
    ///
    private func vaultListItems(
        group: VaultListGroup,
        filter: VaultFilterType,
        from ciphers: [Cipher]
    ) async throws -> [VaultListItem] {
        let ciphers = try await ciphers.asyncMap { cipher in
            try await self.clientVault.ciphers().decrypt(cipher: cipher)
        }
        .filter(filter.cipherFilter)
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let activeCiphers = ciphers.filter { $0.deletedDate == nil }
        let deletedCiphers = ciphers.filter { $0.deletedDate != nil }

        switch group {
        case .card:
            return activeCiphers.filter { $0.type == .card }.compactMap(VaultListItem.init)
        case let .collection(id, _):
            return activeCiphers.filter { $0.collectionIds.contains(id) }.compactMap(VaultListItem.init)
        case let .folder(id, _):
            return activeCiphers.filter { $0.folderId == id }.compactMap(VaultListItem.init)
        case .identity:
            return activeCiphers.filter { $0.type == .identity }.compactMap(VaultListItem.init)
        case .login:
            return activeCiphers.filter { $0.type == .login }.compactMap(VaultListItem.init)
        case .secureNote:
            return activeCiphers.filter { $0.type == .secureNote }.compactMap(VaultListItem.init)
        case .totp:
            return try await totpListItems(from: ciphers, filter: filter)
        case .trash:
            return deletedCiphers.compactMap(VaultListItem.init)
        }
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
        let ciphers = try await ciphers.asyncMap { cipher in
            try await self.clientVault.ciphers().decrypt(cipher: cipher)
        }
        .filter(filter.cipherFilter)
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let folders = try await clientVault.folders()
            .decryptList(folders: folders)
            .filter(filter.folderFilter)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let collections = try await clientVault.collections()
            .decryptList(collections: collections)
            .filter(filter.collectionFilter)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        guard !ciphers.isEmpty else { return [] }

        let activeCiphers = ciphers.filter { $0.deletedDate == nil }

        let ciphersFavorites = activeCiphers.filter(\.favorite).compactMap(VaultListItem.init)
        let ciphersNoFolder = activeCiphers.filter { $0.folderId == nil }.compactMap(VaultListItem.init)

        let ciphersTrashCount = ciphers.lazy.filter { $0.deletedDate != nil }.count
        let ciphersTrashItem = VaultListItem(id: "Trash", itemType: .group(.trash, ciphersTrashCount))

        let oneTimePasswordCount: Int = try await totpListItems(from: ciphers, filter: filter).count

        let totpItems = (oneTimePasswordCount > 0) ? [
            VaultListItem(
                id: "Types.VerificationCodes",
                itemType: .group(
                    .totp,
                    oneTimePasswordCount
                )
            ),
        ] : []

        let folderItems: [VaultListItem] = folders.compactMap { folder in
            guard let folderId = folder.id else {
                self.errorReporter.log(
                    error: BitwardenError.dataError("Received a folder from the API with a missing ID.")
                )
                return nil
            }
            let cipherCount = activeCiphers.lazy.filter { $0.folderId == folderId }.count
            return VaultListItem(
                id: folderId,
                itemType: .group(.folder(id: folderId, name: folder.name), cipherCount)
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
                itemType: .group(.collection(id: collectionId, name: collection.name), collectionCount)
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
            VaultListSection(id: "NoFolder", items: ciphersNoFolder, name: Localizations.folderNone),
            VaultListSection(id: "Collections", items: collectionItems, name: Localizations.collections),
            VaultListSection(id: "Trash", items: [ciphersTrashItem], name: Localizations.trash),
        ].filter { !$0.items.isEmpty }
    }
}

extension DefaultVaultRepository: VaultRepository {
    // MARK: API Methods

    func fetchSync(isManualRefresh: Bool) async throws {
        let allowSyncOnRefresh = try await stateService.getAllowSyncOnRefresh()
        if !isManualRefresh || allowSyncOnRefresh {
            try await syncService.fetchSync()
        }
    }

    // MARK: Data Methods

    func addCipher(_ cipher: CipherView) async throws {
        let cipher = try await clientVault.ciphers().encrypt(cipherView: cipher)
        try await cipherService.addCipherWithServer(cipher)
    }

    func fetchCipher(withId id: String) async throws -> CipherView? {
        guard let cipher = try await cipherService.fetchCipher(withId: id) else { return nil }
        return try? await clientVault.ciphers().decrypt(cipher: cipher)
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
        return try await clientVault.collections()
            .decryptList(collections: collections)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func deleteCipher(_ id: String) async throws {
        try await cipherService.deleteCipherWithServer(id: id)
    }

    func fetchFolders() async throws -> [FolderView] {
        let folders = try await folderService.fetchAllFolders()
        return try await clientVault.folders()
            .decryptList(folders: folders)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func doesActiveAccountHavePremium() async throws -> Bool {
        let account = try await stateService.getActiveAccount()
        return account.profile.hasPremiumPersonally ?? false
    }

    func getDisableAutoTotpCopy() async throws -> Bool {
        try await stateService.getDisableAutoTotpCopy()
    }

    func refreshTOTPCode(for key: TOTPKeyModel) async throws -> LoginTOTPState {
        let codeState = try await clientVault.generateTOTPCode(
            for: key.rawAuthenticatorKey,
            date: Date()
        )
        return LoginTOTPState(
            authKeyModel: key,
            codeModel: codeState
        )
    }

    func refreshTOTPCodes(for items: [VaultListItem]) async throws -> [VaultListItem] {
        try await items.asyncMap { item in
            guard case let .totp(name, model) = item.itemType,
                  let key = model.loginView.totp else {
                return item
            }
            let code = try await clientVault.generateTOTPCode(for: key, date: Date())
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

    func shareCipher(_ cipher: CipherView) async throws {
        let encryptedCipher = try await clientVault.ciphers().encrypt(cipherView: cipher)
        try await cipherService.shareCipherWithServer(encryptedCipher)
    }

    func searchCipherPublisher(
        searchText: String,
        filterType: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListItem], Error>> {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        return try await cipherService.ciphersPublisher().asyncTryMap { ciphers -> [VaultListItem] in
            // Convert the Ciphers to CipherViews and filter appropriately.
            let activeCiphers = try await ciphers.asyncMap { cipher in
                try await self.clientVault.ciphers().decrypt(cipher: cipher)
            }
            .filter { filterType.cipherFilter($0) && $0.deletedDate == nil }

            var matchedCiphers: [CipherView] = []
            var lowPriorityMatchedCiphers: [CipherView] = []

            // Search the ciphers.
            activeCiphers.forEach { cipherView in
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
            let result = matchedCiphers.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending } +
                lowPriorityMatchedCiphers
            return result.compactMap { VaultListItem(cipherView: $0) }
        }.eraseToAnyPublisher().values
    }

    func softDeleteCipher(_ cipher: CipherView) async throws {
        guard let id = cipher.id else { throw CipherAPIServiceError.updateMissingId }
        let softDeletedCipher = cipher.update(deletedDate: .now)
        let encryptCipher = try await clientVault.ciphers().encrypt(cipherView: softDeletedCipher)
        try await cipherService.softDeleteCipherWithServer(id: id, encryptCipher)
    }

    func updateCipher(_ cipherView: CipherView) async throws {
        let cipher = try await clientVault.ciphers().encrypt(cipherView: cipherView)
        try await cipherService.updateCipherWithServer(cipher)
    }

    func updateCipherCollections(_ cipherView: CipherView) async throws {
        let cipher = try await clientVault.ciphers().encrypt(cipherView: cipherView)
        try await cipherService.updateCipherCollectionsWithServer(cipher)
    }

    func validatePassword(_ password: String) async throws -> Bool {
        guard let passwordHash = try await stateService.getMasterPasswordHash() else { return false }
        return try await clientAuth.validatePassword(password: password, passwordHash: passwordHash)
    }

    // MARK: Publishers

    func cipherPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[CipherListView], Error>> {
        try await cipherService.ciphersPublisher()
            .asyncTryMap { ciphers in
                try await self.clientVault.ciphers().decryptList(ciphers: ciphers)
                    .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            }
            .eraseToAnyPublisher()
            .values
    }

    func cipherDetailsPublisher(id: String) async throws -> AsyncThrowingPublisher<AnyPublisher<CipherView?, Error>> {
        try await cipherService.ciphersPublisher()
            .asyncTryMap { ciphers -> CipherView? in
                guard let cipher = ciphers.first(where: { $0.id == id }) else { return nil }
                return try await self.clientVault.ciphers().decrypt(cipher: cipher)
            }
            .eraseToAnyPublisher()
            .values
    }

    func ciphersAutofillPublisher(
        uri: String?
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[CipherView], Error>> {
        try await cipherService.ciphersPublisher()
            .asyncTryMap { ciphers in
                try await ciphers.asyncMap { cipher in
                    try await self.clientVault.ciphers().decrypt(cipher: cipher)
                }
            }
            .map { ciphers in
                CipherMatchingHelper.ciphersMatching(uri: uri, ciphers: ciphers)
            }
            .eraseToAnyPublisher()
            .values
    }

    func organizationsPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[Organization], Error>> {
        try await organizationService.organizationsPublisher().eraseToAnyPublisher().values
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
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListItem], Error>> {
        try await cipherService.ciphersPublisher()
            .asyncTryMap { ciphers in
                try await self.vaultListItems(group: group, filter: filter, from: ciphers)
            }
            .eraseToAnyPublisher()
            .values
    }
} // swiftlint:disable:this file_length
