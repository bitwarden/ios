import BitwardenSdk

// MARK: - VaultListArrangedDataBuilderFactory

/// A factory protocol to make vault list arranged data builders.
protocol VaultListArrangedDataBuilderFactory {
    func make() -> VaultListArrangedDataBuilder
}

// MARK: - DefaultVaultListArrangedDataBuilderFactory

/// The default implemetnation of `VaultListArrangedDataBuilderFactory`.
struct DefaultVaultListArrangedDataBuilderFactory: VaultListArrangedDataBuilderFactory {
    // swiftlint:disable:previous type_name

    let stateService: StateService

    func make() -> VaultListArrangedDataBuilder {
        DefaultVaultListArrangedDataBuilder(stateService: stateService)
    }
}

// MARK: - VaultListArrangedDataBuilder

protocol VaultListArrangedDataBuilder {
    func addCollections(collections: [Collection], filterType: VaultFilterType) -> VaultListArrangedDataBuilder
    func addFavoriteItem(cipher: CipherListView) -> VaultListArrangedDataBuilder
    func addFolders(folders: [Folder], filterType: VaultFilterType) -> VaultListArrangedDataBuilder
    func addFolderItem(
        cipher: CipherListView,
        filterType: VaultFilterType,
        folders: [Folder]
    ) -> VaultListArrangedDataBuilder
    func addNoFolderItem(cipher: CipherListView) -> VaultListArrangedDataBuilder
    func build() -> VualtListBuilderMetadata
    func incrementCipherTypeCount(cipher: CipherListView) -> VaultListArrangedDataBuilder
    func incrementCipherDeletedCount() -> VaultListArrangedDataBuilder
    func incrementCollectionCount(cipher: CipherListView) -> VaultListArrangedDataBuilder
    func incrementTOTPCount(cipher: CipherListView) async -> VaultListArrangedDataBuilder
}

class DefaultVaultListArrangedDataBuilder: VaultListArrangedDataBuilder {
    // MARK: Properties

    let stateService: StateService

    var arrangedData = VualtListBuilderMetadata()
    var hasPremiumFeaturesAccess: Bool?

    // MARK: Init

    init(stateService: StateService) {
        self.stateService = stateService
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
        filterType: VaultFilterType,
        folders: [Folder]
    ) -> VaultListArrangedDataBuilder {
        if let folderId = cipher.folderId, let folder = folders.first(where: { $0.id == folderId }) {
            arrangedData.foldersCount[folderId, default: 0] += 1
            if filterType != .allVaults, !arrangedData.folders.contains(where: { $0.id == folderId }) {
                arrangedData.folders.append(folder)
            }
        }

        return self
    }

    func addNoFolderItem(cipher: CipherListView) -> VaultListArrangedDataBuilder {
        if cipher.folderId == nil,
           let noFolderItem = VaultListItem(cipherListView: cipher) {
            arrangedData.noFolderItems.append(noFolderItem)
        }
        return self
    }

    func build() -> VualtListBuilderMetadata {
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
        let hasPremiumFeaturesAccess = await getHasPremiumFeaturesAccesss()

        let hasAccess = hasPremiumFeaturesAccess || cipher.organizationUseTotp
        if hasAccess, cipher.type.loginListView?.totp != nil {
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
}
