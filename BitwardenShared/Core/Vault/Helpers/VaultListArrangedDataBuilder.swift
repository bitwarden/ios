import BitwardenKit
import BitwardenSdk

// MARK: - VaultListArrangedDataBuilderFactory

/// A factory protocol to make vault list arranged data builders.
protocol VaultListArrangedDataBuilderFactory {
    /// Makes a arranged data builder.
    func make() -> VaultListArrangedDataBuilder
}

// MARK: - DefaultVaultListArrangedDataBuilderFactory

/// The default implemetnation of `VaultListArrangedDataBuilderFactory`.
struct DefaultVaultListArrangedDataBuilderFactory: VaultListArrangedDataBuilderFactory {
    // swiftlint:disable:previous type_name

    let clientService: ClientService
    let errorReporter: ErrorReporter
    let stateService: StateService
    let timeProvider: TimeProvider

    func make() -> VaultListArrangedDataBuilder {
        DefaultVaultListArrangedDataBuilder(
            clientService: clientService,
            errorReporter: errorReporter,
            stateService: stateService,
            timeProvider: timeProvider
        )
    }
}

// MARK: - VaultListArrangedDataBuilder

/// Builder to build arranged data for the vault list sections.
protocol VaultListArrangedDataBuilder {
    /// Adds collections to the arranged data.
    func addCollections(collections: [Collection], filterType: VaultFilterType) -> VaultListArrangedDataBuilder
    /// Adds a favorite item to the arranged data.
    func addFavoriteItem(cipher: CipherListView) -> VaultListArrangedDataBuilder
    /// Adds folders to the arranged data.
    func addFolders(folders: [Folder], filterType: VaultFilterType) -> VaultListArrangedDataBuilder
    /// Adds a folder item to the arranged data.
    func addFolderItem(
        cipher: CipherListView,
        filter: VaultListFilter,
        folders: [Folder]
    ) -> VaultListArrangedDataBuilder
    /// Adds an item for a specific group to the arranged data.
    func addItem(forGroup group: VaultListGroup, with cipher: CipherListView) async -> VaultListArrangedDataBuilder
    /// Adds a no folder item to the arranged data.
    func addNoFolderItem(cipher: CipherListView) -> VaultListArrangedDataBuilder
    /// Builds the arranged data.
    func build() -> VaultListBuilderMetadata
    /// Increments the cipher type count in the arranged data.
    func incrementCipherTypeCount(cipher: CipherListView) -> VaultListArrangedDataBuilder
    /// Increments the cipher deleted count in the arranged data.
    func incrementCipherDeletedCount() -> VaultListArrangedDataBuilder
    /// Increments the collection count in the arranged data.
    func incrementCollectionCount(cipher: CipherListView) -> VaultListArrangedDataBuilder
    /// Increments the TOTP count in the arranged data.
    func incrementTOTPCount(cipher: CipherListView) async -> VaultListArrangedDataBuilder
}

class DefaultVaultListArrangedDataBuilder: VaultListArrangedDataBuilder {
    // MARK: Properties

    let clientService: ClientService
    let errorReporter: ErrorReporter
    let stateService: StateService
    let timeProvider: TimeProvider

    /// The arranged data to build.
    var arrangedData = VaultListBuilderMetadata()
    /// Cache of whether the account has premium features access.
    var hasPremiumFeaturesAccess: Bool?
    /// Cache of whether the user has master password.
    var userHasMasterPassword: Bool?

    // MARK: Init

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

    func addCollections(collections: [Collection], filterType: VaultFilterType) -> VaultListArrangedDataBuilder {
        if filterType == .allVaults {
            arrangedData.collections = collections
        } else if case let .organization(organization) = filterType {
            arrangedData.collections = collections.filter { $0.id == organization.id }
        }
        return self
    }

    func addFavoriteItem(cipher: CipherListView) -> VaultListArrangedDataBuilder {
        if cipher.favorite,
           let favoriteListItem = VaultListItem(cipherListView: cipher) {
            arrangedData.favorites.append(favoriteListItem)
        }
        return self
    }

    func addFolders(folders: [Folder], filterType: VaultFilterType) -> VaultListArrangedDataBuilder {
        if filterType == .allVaults {
            arrangedData.folders = folders
        }
        return self
    }

    func addFolderItem(
        cipher: CipherListView,
        filter: VaultListFilter,
        folders: [Folder]
    ) -> VaultListArrangedDataBuilder {
        if let folderId = cipher.folderId, let folder = folders.first(where: { $0.id == folderId }) {
            arrangedData.foldersCount[folderId, default: 0] += 1
            if filter.filterType != .allVaults, !arrangedData.folders.contains(where: { $0.id == folderId }) {
                arrangedData.folders.append(folder)
            }
        }

        return self
    }

    func addItem(
        forGroup group: VaultListGroup,
        with cipher: CipherListView
    ) async -> any VaultListArrangedDataBuilder {
        guard cipher.deletedDate == nil else {
            if group == .trash, let trashItem = VaultListItem(cipherListView: cipher) {
                arrangedData.groupItems.append(trashItem)
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
                arrangedData.groupItems.append(totpItem)
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
        arrangedData.groupItems.append(groupItem)
        return self
    }

    func addNoFolderItem(cipher: CipherListView) -> VaultListArrangedDataBuilder {
        if cipher.folderId == nil,
           let noFolderItem = VaultListItem(cipherListView: cipher) {
            arrangedData.noFolderItems.append(noFolderItem)
        }
        return self
    }

    func build() -> VaultListBuilderMetadata {
        arrangedData
    }

    func incrementCipherTypeCount(cipher: CipherListView) -> VaultListArrangedDataBuilder {
        switch cipher.type {
        case .card:
            arrangedData.countPerCipherType[.card, default: 0] += 1
        case .identity:
            arrangedData.countPerCipherType[.identity, default: 0] += 1
        case .login:
            arrangedData.countPerCipherType[.login, default: 0] += 1
        case .secureNote:
            arrangedData.countPerCipherType[.secureNote, default: 0] += 1
        case .sshKey:
            arrangedData.countPerCipherType[.sshKey, default: 0] += 1
        }

        return self
    }

    func incrementCipherDeletedCount() -> VaultListArrangedDataBuilder {
        arrangedData.ciphersDeletedCount += 1
        return self
    }

    func incrementCollectionCount(cipher: CipherListView) -> VaultListArrangedDataBuilder {
        if !cipher.collectionIds.isEmpty,
           let tempCollectionForCipher = arrangedData.collections.first(where: { collection in
               guard let colId = collection.id else { return false }
               return cipher.collectionIds.contains(colId)
           }),
           let tempCollectionId = tempCollectionForCipher.id {
            arrangedData.collectionsCount[tempCollectionId, default: 0] += 1
        }

        return self
    }

    func incrementTOTPCount(cipher: CipherListView) async -> VaultListArrangedDataBuilder {
        if await shouldIncludeTOTP(cipher: cipher) {
            arrangedData.totpItemsCount += 1
        }

        return self
    }

    // MARK: Private methods

    private func getHasPremiumFeaturesAccesss() async -> Bool {
        guard let hasPremiumFeaturesAccess else {
            hasPremiumFeaturesAccess = await stateService.safeDoesActiveAccountHavePremium()
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
        let hasPremiumFeaturesAccess = await getHasPremiumFeaturesAccesss()

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
