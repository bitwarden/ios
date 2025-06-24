
import BitwardenKit
import BitwardenSdk

protocol VaultListDataArranger {
    /// Arranges metadata for the vault list builder based.
    /// - Parameters:
    ///   - ciphers: An array of `Cipher` objects to be processed.
    ///   - collections: An array of `Collection` objects to be processed.
    ///   - folders: An array of `Folder` objects to be processed.
    ///   - filter: A `VaultListFilter` object that defines the filtering criteria for the vault list.
    /// - Returns: An optional `VaultListBuilderMetadata` object containing the arranged metadata for the vault list.
    func arrangeMetadata(
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter
    ) async throws -> VaultListBuilderMetadata?
    
    /// Arranges group metadata for the vault list builder.
    /// - Parameters:
    ///   - ciphers: An array of `Cipher` objects to be processed.
    ///   - collections: An array of `Collection` objects to be processed.
    ///   - folders: An array of `Folder` objects to be processed.
    ///   - filter: A `VaultListFilter` object that defines the filtering criteria for the vault list.
    /// - Returns: An optional `VaultListBuilderMetadata` object containing the arranged metadata for the vault list.
    func arrangeGroupMetadata(
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter
    ) async throws -> VaultListBuilderMetadata?
}

/// Default implementation of `VaultListDataArranger`.
struct DefaultVaultListDataArranger: VaultListDataArranger {
    // MARK: Properties

    let clientService: ClientService
    let ciphersClientWrapperService: CiphersClientWrapperService
    let errorReporter: ErrorReporter
    let stateService: StateService
    let vaultListArrangedDataBuilderFactory: VaultListArrangedDataBuilderFactory

    // MARK: Methods

    func arrangeMetadata(
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter
    ) async throws -> VaultListBuilderMetadata? {
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
                .addFolderItem(cipher: decryptedCipher, filter: filter, folders: folders)
                .addFavoriteItem(cipher: decryptedCipher)
                .addNoFolderItem(cipher: decryptedCipher)
                .incrementCipherTypeCount(cipher: decryptedCipher)
                .incrementCollectionCount(cipher: decryptedCipher)
        }

        return arrangedDataBuilder.build()
    }

    func arrangeGroupMetadata(
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter
    ) async throws -> VaultListBuilderMetadata? {
        guard !ciphers.isEmpty, let group = filter.group else {
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

            if case .folder = filter.group {
                arrangedDataBuilder = arrangedDataBuilder.addFolderItem(
                    cipher: decryptedCipher,
                    filter: filter,
                    folders: folders
                )
            }

            if case .collection = filter.group {
                arrangedDataBuilder = arrangedDataBuilder.incrementCollectionCount(cipher: decryptedCipher)
            }

            arrangedDataBuilder = await arrangedDataBuilder.addItem(forGroup: group, with: decryptedCipher)
        }

        return arrangedDataBuilder.build()
    }
}
