import BitwardenKit
import BitwardenSdk

// MARK: - VaultListPreparedDataBuilderFactory

/// A factory protocol to make vault list prepared data builders.
protocol VaultListPreparedDataBuilderFactory { // sourcery: AutoMockable
    /// Makes a builder for `VaultListPreparedData`.
    func make() -> VaultListPreparedDataBuilder
}

// MARK: - DefaultVaultListPreparedDataBuilderFactory

/// The default implementation of `VaultListPreparedDataBuilderFactory`.
struct DefaultVaultListPreparedDataBuilderFactory: VaultListPreparedDataBuilderFactory {
    /// The service used by the application to handle encryption and decryption tasks.
    let clientService: ClientService
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter
    /// The service used by the application to manage account state.
    let stateService: StateService
    /// Provides the present time.
    let timeProvider: TimeProvider

    func make() -> VaultListPreparedDataBuilder {
        DefaultVaultListPreparedDataBuilder(
            clientService: clientService,
            errorReporter: errorReporter,
            stateService: stateService,
            timeProvider: timeProvider
        )
    }
}

// MARK: - VaultListPreparedDataBuilder

/// Builder to build prepared data for the vault list sections.
protocol VaultListPreparedDataBuilder { // sourcery: AutoMockable
    /// Adds a cipher item which failed to decrypt.
    func addCipherDecryptionFailure(cipher: CipherListView) -> VaultListPreparedDataBuilder
    /// Adds a favorite item to the prepared data.
    func addFavoriteItem(cipher: CipherListView) -> VaultListPreparedDataBuilder
    /// Adds a folder item to the prepared data.
    func addFolderItem(
        cipher: CipherListView,
        filter: VaultListFilter,
        folders: [Folder]
    ) -> VaultListPreparedDataBuilder
    /// Adds an item for a specific group to the prepared data.
    func addItem(forGroup group: VaultListGroup, with cipher: CipherListView) async -> VaultListPreparedDataBuilder
    /// Adds an item with a match result strength to the prepared data.
    func addItem( // sourcery: useSelectorName
        withMatchResult matchResult: CipherMatchResult,
        cipher: CipherListView
    ) async -> VaultListPreparedDataBuilder
    /// Adds a no folder item to the prepared data.
    func addNoFolderItem(cipher: CipherListView) -> VaultListPreparedDataBuilder
    /// Builds the prepared data.
    func build() -> VaultListPreparedData
    /// Increments the cipher type count in the prepared data.
    func incrementCipherTypeCount(cipher: CipherListView) -> VaultListPreparedDataBuilder
    /// Increments the cipher deleted count in the prepared data.
    func incrementCipherDeletedCount() -> VaultListPreparedDataBuilder
    /// Increments the collection count in the prepared data.
    func incrementCollectionCount(cipher: CipherListView) -> VaultListPreparedDataBuilder
    /// Increments the TOTP count in the prepared data.
    func incrementTOTPCount(cipher: CipherListView) async -> VaultListPreparedDataBuilder
    /// Prepares collections to the prepared data that then can be used for filtering.
    func prepareCollections(collections: [Collection], filterType: VaultFilterType) -> VaultListPreparedDataBuilder
    /// Prepares folders to the prepared data that then can be used for filtering.
    func prepareFolders(folders: [Folder], filterType: VaultFilterType) -> VaultListPreparedDataBuilder
    /// Prepares the sections with restricted organization IDs.
    @discardableResult
    func prepareRestrictItemsPolicyOrganizations(restrictedOrganizationIds: [String]) -> VaultListPreparedDataBuilder
}

// MARK: - DefaultVaultListPreparedDataBuilder

/// Default implementation of `VaultListPreparedDataBuilder`.
class DefaultVaultListPreparedDataBuilder: VaultListPreparedDataBuilder {
    // MARK: Properties

    /// The service that handles common client functionality such as encryption and decryption.
    let clientService: ClientService
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter
    /// The service used by the application to manage account state.
    let stateService: StateService
    /// The service used to get the present time.
    let timeProvider: TimeProvider

    /// The prepared data to build.
    var preparedData = VaultListPreparedData()
    /// Cache of whether the account has premium features access.
    var hasPremiumFeaturesAccess: Bool?
    /// Cache of whether the user has master password.
    var userHasMasterPassword: Bool?

    // MARK: Init

    /// Initializes a `DefaultVaultListPreparedDataBuilder`.
    /// - Parameters:
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The service used by the application to manage account state.
    ///   - timeProvider: The service used to get the present time.
    init(
        clientService: ClientService,
        errorReporter: ErrorReporter,
        stateService: StateService,
        timeProvider: TimeProvider
    ) {
        self.clientService = clientService
        self.errorReporter = errorReporter
        self.stateService = stateService
        self.timeProvider = timeProvider
    }

    // MARK: Methods

    func addCipherDecryptionFailure(cipher: CipherListView) -> VaultListPreparedDataBuilder {
        if cipher.isDecryptionFailure, let id = cipher.id {
            preparedData.cipherDecryptionFailureIds.append(id)
        }
        return self
    }

    func addFavoriteItem(cipher: CipherListView) -> VaultListPreparedDataBuilder {
        if cipher.favorite,
           let favoriteListItem = VaultListItem(cipherListView: cipher) {
            preparedData.favorites.append(favoriteListItem)
        }
        return self
    }

    func addFolderItem(
        cipher: CipherListView,
        filter: VaultListFilter,
        folders: [Folder]
    ) -> VaultListPreparedDataBuilder {
        if let folderId = cipher.folderId, let folder = folders.first(where: { $0.id == folderId }) {
            preparedData.foldersCount[folderId, default: 0] += 1
            if filter.filterType != .allVaults, !preparedData.folders.contains(where: { $0.id == folderId }) {
                preparedData.folders.append(folder)
            }
        }

        return self
    }

    func addItem( // swiftlint:disable:this cyclomatic_complexity
        forGroup group: VaultListGroup,
        with cipher: CipherListView
    ) async -> any VaultListPreparedDataBuilder {
        guard cipher.deletedDate == nil else {
            if group == .trash, let trashItem = VaultListItem(cipherListView: cipher) {
                preparedData.groupItems.append(trashItem)
            }
            return self
        }

        switch group {
        case .card:
            guard cipher.type.isCard else { return self }
        case .identity:
            guard cipher.type == .identity else { return self }
        case .login:
            guard cipher.type.isLogin else { return self }
        case .secureNote:
            guard cipher.type == .secureNote else { return self }
        case .sshKey:
            guard cipher.type == .sshKey else { return self }
        case .totp:
            if await shouldIncludeTOTP(cipher: cipher),
               let totpItem = await totpItem(for: cipher) {
                preparedData.groupItems.append(totpItem)
            }
            return self
        case let .collection(id, _, _):
            guard cipher.collectionIds.contains(id) else { return self }
        case let .folder(id, _):
            guard cipher.folderId == id else { return self }
        case .noFolder:
            guard cipher.folderId == nil else { return self }
        case .trash:
            // this case is handled at the beginning of the function.
            return self
        }

        guard let groupItem = VaultListItem(cipherListView: cipher) else {
            return self
        }
        preparedData.groupItems.append(groupItem)
        return self
    }

    func addItem(
        withMatchResult matchResult: CipherMatchResult,
        cipher: CipherListView
    ) async -> VaultListPreparedDataBuilder {
        guard matchResult != .none, let vaultListItem = VaultListItem(cipherListView: cipher) else {
            return self
        }

        switch matchResult {
        case .exact:
            preparedData.exactMatchItems.append(vaultListItem)
        case .fuzzy:
            preparedData.fuzzyMatchItems.append(vaultListItem)
        case .none:
            break
        }

        return self
    }

    func addNoFolderItem(cipher: CipherListView) -> VaultListPreparedDataBuilder {
        if cipher.folderId == nil,
           let noFolderItem = VaultListItem(cipherListView: cipher) {
            preparedData.noFolderItems.append(noFolderItem)
        }
        return self
    }

    func build() -> VaultListPreparedData {
        preparedData
    }

    func incrementCipherTypeCount(cipher: CipherListView) -> VaultListPreparedDataBuilder {
        preparedData.countPerCipherType[CipherType(cipher.type), default: 0] += 1
        return self
    }

    func incrementCipherDeletedCount() -> VaultListPreparedDataBuilder {
        preparedData.ciphersDeletedCount += 1
        return self
    }

    func incrementCollectionCount(cipher: CipherListView) -> VaultListPreparedDataBuilder {
        if !cipher.collectionIds.isEmpty {
            let tempCollectionsForCipher = preparedData.collections.filter { collection in
                guard let colId = collection.id else { return false }
                return cipher.collectionIds.contains(colId)
            }
            tempCollectionsForCipher.forEach { tempCollection in
                if let collectionId = tempCollection.id {
                    preparedData.collectionsCount[collectionId, default: 0] += 1
                }
            }
        }

        return self
    }

    func incrementTOTPCount(cipher: CipherListView) async -> VaultListPreparedDataBuilder {
        if await shouldIncludeTOTP(cipher: cipher) {
            preparedData.totpItemsCount += 1
        }

        return self
    }

    func prepareCollections(collections: [Collection], filterType: VaultFilterType) -> VaultListPreparedDataBuilder {
        if filterType == .allVaults {
            preparedData.collections = collections
        } else if case let .organization(organization) = filterType {
            preparedData.collections = collections.filter { $0.organizationId == organization.id }
        }
        return self
    }

    func prepareFolders(folders: [Folder], filterType: VaultFilterType) -> VaultListPreparedDataBuilder {
        if filterType == .allVaults {
            preparedData.folders = folders
        }
        return self
    }

    @discardableResult
    func prepareRestrictItemsPolicyOrganizations(restrictedOrganizationIds: [String]) -> VaultListPreparedDataBuilder {
        preparedData.restrictedOrganizationIds = restrictedOrganizationIds
        return self
    }

    // MARK: Private methods

    private func getHasPremiumFeaturesAccess() async -> Bool {
        guard let hasPremiumFeaturesAccess else {
            hasPremiumFeaturesAccess = await stateService.doesActiveAccountHavePremium()
            return hasPremiumFeaturesAccess ?? false
        }
        return hasPremiumFeaturesAccess
    }

    private func getUserHasMasterPassword() async -> Bool {
        guard let userHasMasterPassword else {
            userHasMasterPassword = await (try? stateService.getUserHasMasterPassword()) ?? false
            return userHasMasterPassword ?? false
        }
        return userHasMasterPassword
    }

    private func shouldIncludeTOTP(cipher: CipherListView) async -> Bool {
        let hasPremiumFeaturesAccess = await getHasPremiumFeaturesAccess()

        let hasAccess = hasPremiumFeaturesAccess || cipher.organizationUseTotp
        return hasAccess && cipher.type.loginListView?.totp != nil
    }

    private func totpItem(
        for cipherListView: CipherListView
    ) async -> VaultListItem? {
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

        let userHasMasterPassword = await getUserHasMasterPassword()

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
}
