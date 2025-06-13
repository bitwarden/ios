import BitwardenKit
import BitwardenSdk

protocol VaultListDataArranger {
    func arrangeMetadata(
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter
    ) async throws -> VualtListBuilderMetadata?

    func arrangeMetadata2(
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter
    ) async throws -> VualtListBuilderMetadata?
}

struct DefaultVaultListDataArranger: VaultListDataArranger {
    // MARK: Static properties

    // MARK: Properties

    let clientService: ClientService
    let ciphersClientWrapperService: CiphersClientWrapperService
    let errorReporter: ErrorReporter
    let stateService: StateService
    let vaultListArrangedDataBuilderFactory: VaultListArrangedDataBuilderFactory

    // MARK: Init

    init(
        clientService: ClientService, 
        ciphersClientWrapperService: CiphersClientWrapperService,
        errorReporter: ErrorReporter,
        stateService: StateService,
        vaultListArrangedDataBuilderFactory: VaultListArrangedDataBuilderFactory
    ) {
        self.clientService = clientService
        self.ciphersClientWrapperService = ciphersClientWrapperService
        self.errorReporter = errorReporter
        self.stateService = stateService
        self.vaultListArrangedDataBuilderFactory = vaultListArrangedDataBuilderFactory
    }

    // MARK: Methods

    func arrangeMetadata(
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter
    ) async throws -> VualtListBuilderMetadata? {
        guard !ciphers.isEmpty else {
            return nil
        }

        var tempData = VualtListBuilderMetadata()

        // TOTP
        var hasPremiumFeaturesAccess = false
        if filter.addTOTPGroup {
            hasPremiumFeaturesAccess = await (try? stateService.doesActiveAccountHavePremium()) ?? false
        }

        // Collections
        if filter.filterType == .allVaults {
            tempData.collections = collections
        } else if case let .organization(organization) = filter.filterType {
            tempData.collections = collections.filter { $0.id == organization.id }
        }

        // Ciphers iterator

        for sliceStartIndex in stride(from: 0, to: ciphers.count, by: Constants.decryptCiphersBatchSize) {
            let sliceEndIndex = min(sliceStartIndex + Constants.decryptCiphersBatchSize, ciphers.count)

            do {
                var decryptedCiphers = try await clientService.vault().ciphers().decryptList(
                    ciphers: Array(ciphers[sliceStartIndex ..< sliceEndIndex])
                )

                guard !decryptedCiphers.isEmpty else {
                    continue
                }

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
                        tempData.folders = folders
                    }

                    if let folderId = decryptedCipher.folderId, let folder = folders.first(where: { $0.id == folderId }) {
                        tempData.foldersCount[folderId, default: 0] += 1
                        if filter.filterType != .allVaults, !tempData.folders.contains(where: { $0.id == folderId }) {
                            tempData.folders.append(folder)
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
                       let tempCollectionForCipher = tempData.collections.first(where: { collection in
                           guard let colId = collection.id else { return false }
                           return decryptedCipher.collectionIds.contains(colId)
                       }),
                       let tempCollectionId = tempCollectionForCipher.id {
                        tempData.collectionsCount[tempCollectionId, default: 0] += 1
                    }

                    i += 1
                } // end while
            } catch {
                errorReporter.log(error: error)
            }

//            if sliceEndIndex < ciphers.count - 1 {
//                sliceStartIndex = sliceEndIndex + 1
//                sliceEndIndex = ciphers.count >= sliceEndIndex + Constants.decryptCiphersBatchSize
//                    ? sliceEndIndex + Constants.decryptCiphersBatchSize
//                    : ciphers.count - 1
//            } else {
//                break
//            }
        }

        return tempData
    }

    func arrangeMetadata2(
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter
    ) async throws -> VualtListBuilderMetadata? {
        guard !ciphers.isEmpty else {
            return nil
        }

        var arrangedDataBuilder = vaultListArrangedDataBuilderFactory.make()

        arrangedDataBuilder = arrangedDataBuilder
            .addFolders(folders: folders, filterType: filter.filterType)
            .addCollections(collections: collections, filterType: filter.filterType)

        await ciphersClientWrapperService.decryptAndProcessCiphersInBatch(
            ciphers: ciphers
        ) { decryptedCipher in
            guard filter.filterType.cipherFilter(decryptedCipher) else {
                return
            }

            guard decryptedCipher.deletedDate == nil else {
                arrangedDataBuilder = arrangedDataBuilder.incrementCipherDeletedCount()
                return
            }

            if filter.addTOTPGroup {
                arrangedDataBuilder = await arrangedDataBuilder.incrementTOTPCount(cipher: decryptedCipher)
            }

            arrangedDataBuilder = arrangedDataBuilder
                .addFolderItem(cipher: decryptedCipher, filterType: filter.filterType, folders: folders)
                .addFavoriteItem(cipher: decryptedCipher)
                .addNoFolderItem(cipher: decryptedCipher)
                .incrementCipherTypeCount(cipher: decryptedCipher)
                .incrementCollectionCount(cipher: decryptedCipher)
        }

        return arrangedDataBuilder.build()
    }

//    func iterateDecryptingCiphersBySlice(ciphers: [Cipher], onCipher: (CipherListView) async throws -> Void) async {
//        for start in stride(from: 0, to: ciphers.count, by: Self.decryptCiphersSliceSize) {
//            let end = min(start + Self.decryptCiphersSliceSize, ciphers.count)
//            do {
//                var decryptedCiphers = try await clientService.vault().ciphers().decryptList(
//                    ciphers: Array(ciphers[start..<end])
//                )
//
//                guard !decryptedCiphers.isEmpty else {
//                    continue
//                }
//
//                for decryptedCipher in decryptedCiphers {
//                    try await onCipher(decryptedCipher)
//                }
//            } catch {
//                errorReporter.log(error: error)
//            }
//        }
//    }
}
