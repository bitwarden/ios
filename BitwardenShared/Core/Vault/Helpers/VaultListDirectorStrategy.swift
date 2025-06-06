import BitwardenKit
import BitwardenSdk

// MARK: - VaultListDirectorStrategy

protocol VaultListDirectorStrategy {
    func build(
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter
    ) async throws -> [VaultListSection]
}

// MARK: - DefaultVaultListDirectorStrategy

struct DefaultVaultListDirectorStrategy: VaultListDirectorStrategy {
    // MARK: Static properties

    /// The size of the slice to decrypt ciphers in batch using the SDK.
    static let decryptCiphersSliceSize: Int = 100

    let builderFactory: VaultListBuilderFactory
    let clientService: ClientService
    let errorReporter: ErrorReporter
    let stateService: StateService

    func build( // swiftlint:disable:this function_body_length
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter
    ) async throws -> [VaultListSection] {
        guard !ciphers.isEmpty else { return [] }

        var tempData = VualtListBuilderMetadata()
        var validFolders: [Folder] = []

        // TOTP
        var hasPremiumFeaturesAccess = false
        if filter.addTOTPGroup {
            hasPremiumFeaturesAccess = await (try? stateService.doesActiveAccountHavePremium()) ?? false
        }

        // Collections
        var tempCollections: [Collection] = []
        if filter.filterType == .allVaults {
            tempCollections = collections
        } else if case let .organization(organization) = filter.filterType {
            tempCollections = collections.filter { $0.id == organization.id }
        }

//        let nestedCollections = if let nestedCollectionId {
//            collectionTree.getTreeNodeObject(with: nestedCollectionId)?.children
//        } else {
//            collectionTree.rootNodes
//        }

        // Ciphers iterator

        var sliceStartIndex = 0
        var sliceEndIndex = ciphers.count >= Self.decryptCiphersSliceSize ? Self.decryptCiphersSliceSize : ciphers.count - 1
        while sliceEndIndex < ciphers.count {
            var decryptedCiphers = try await clientService.vault().ciphers().decryptList(
                ciphers: Array(ciphers[sliceStartIndex...sliceEndIndex])
            )

            guard !decryptedCiphers.isEmpty else { return [] }

            var i = 0 // swiftlint:disable:this identifier_name
            var removedCiphersCount = 0
            while i < decryptedCiphers.count - removedCiphersCount {
                guard filter.filterType.cipherFilter(decryptedCiphers[i]) else {
                    decryptedCiphers.remove(at: i)
                    removedCiphersCount += 1
                    continue
                }

                guard decryptedCiphers[i].deletedDate == nil else {
                    tempData.ciphersDeletedCount += 1
                    i += 1
                    continue
                }

                let decryptedCipher = decryptedCiphers[i]

                if filter.filterType == .allVaults {
                    validFolders = folders
                }

                if let folderId = decryptedCipher.folderId,
                   let folder = folders.first(where: { $0.id == folderId })
                {
                    tempData.foldersCount[folderId, default: 0] += 1
                    if filter.filterType != .allVaults, !validFolders.contains(where: { $0.id == folderId }) {
                        validFolders.append(folder)
                    }
                }

                if decryptedCipher.favorite,
                   let favoriteListItem = VaultListItem(cipherListView: decryptedCipher) {
                    tempData.favorites.append(favoriteListItem)
                }

                if decryptedCipher.folderId == nil,
                   let noFolderItem = VaultListItem(cipherListView: decryptedCipher) {
                    tempData.noFolderItems.append(noFolderItem)
                }

                switch decryptedCipher.type {
                case .card:
                    tempData.countPerCipherType[.card, default: 0] += 1
                case .identity:
                    tempData.countPerCipherType[.identity, default: 0] += 1
                case let .login(decryptedLogin):
                    tempData.countPerCipherType[.login, default: 0] += 1

                    let hasAccess = hasPremiumFeaturesAccess || decryptedCipher.organizationUseTotp
                    if filter.addTOTPGroup,
                       decryptedLogin.totp != nil,
                       hasAccess {
                        tempData.totpItemsCount += 1
                    }
                case .secureNote:
                    tempData.countPerCipherType[.secureNote, default: 0] += 1
                case .sshKey:
                    tempData.countPerCipherType[.sshKey, default: 0] += 1
                }

                if !decryptedCipher.collectionIds.isEmpty,
                   let tempCollectionForCipher = tempCollections.first(where: {
                       guard let colId = $0.id else { return false }
                       return decryptedCipher.collectionIds.contains(colId)
                   }),
                   let tempCollectionId = tempCollectionForCipher.id
                {
                    tempData.collectionsCount[tempCollectionId, default: 0] += 1
                }

                i += 1
            } // end while

            if sliceEndIndex < ciphers.count - 1 {
                sliceStartIndex = sliceEndIndex + 1
                sliceEndIndex = ciphers.count >= sliceEndIndex + Self.decryptCiphersSliceSize
                    ? sliceEndIndex + Self.decryptCiphersSliceSize
                    : ciphers.count - 1
            } else {
                break
            }
        }

        // BUILD SECTIONS

        var builder = builderFactory.make()

        if filter.addTOTPGroup {
            builder = builder.appendTOTPSection(from: &tempData)
        }

        builder = try await builder
            .appendFavoritesSection(from: &tempData)
            .appendTypesSection(from: &tempData)
            .appendFoldersSection(
                from: &tempData,
                havingCollections: !tempCollections.isEmpty,
                with: &validFolders
            )
            .appendCollectionsSection(from: &tempData, with: &tempCollections)

        // Trash section
        if filter.addTrashGroup {
            builder = builder.appendTrashSection(from: &tempData)
        }

        return builder.build()
    }
}

// MARK: - VualtListBuilderMetadata

/// Metadata helper object to hold temporary data the builder can then use to build the list sections.
struct VualtListBuilderMetadata {
    var ciphersDeletedCount: Int = 0
    var collectionsCount: [Uuid: Int] = [:]
    var countPerCipherType: [BitwardenSdk.CipherType: Int] = [
        .card: 0,
        .identity: 0,
        .login: 0,
        .secureNote: 0,
        .sshKey: 0,
    ]
    var favorites: [VaultListItem] = []
    var foldersCount: [Uuid: Int] = [:]
    var noFolderItems: [VaultListItem] = []
    var totpItemsCount: Int = 0
}

// MARK: - VaultListDirectorOptions

struct VaultListDirectorOptions {

}
