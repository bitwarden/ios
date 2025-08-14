import BitwardenKit
import BitwardenSdk
import Combine

// MARK: - MainVaultListDirectorStrategy

/// The director strategy to be used to build the main vault sections.
struct MainVaultListDirectorStrategy: VaultListDirectorStrategy {
    // MARK: Properties

    /// The factory for creating vault list builders.
    let builderFactory: VaultListSectionsBuilderFactory
    /// The service used to manage syncing and updates to the user's ciphers.
    let cipherService: CipherService
    /// The service for managing the collections for the user.
    let collectionService: CollectionService
    /// The service used to manage syncing and updates to the user's folders.
    let folderService: FolderService
    /// The helper used to prepare data for the vault list builder.
    let vaultListDataPreparator: VaultListDataPreparator

    func build(
        filter: VaultListFilter
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>> {
        try await Publishers.CombineLatest3(
            cipherService.ciphersPublisher(),
            collectionService.collectionsPublisher(),
            folderService.foldersPublisher()
        )
        .asyncTryMap { ciphers, collections, folders in
            try await build(from: ciphers, collections: collections, folders: folders, filter: filter)
        }
        .eraseToAnyPublisher()
        .values
    }

    // MARK: Private methods

    /// Builds the vault list sections.
    /// - Parameters:
    ///   - ciphers: Ciphers to filter and include in the sections.
    ///   - collections: Collections to filter and include in the sections.
    ///   - folders: Folders to filter and include in the sections.
    ///   - filter: Filter to be used to build the sections.
    /// - Returns: Vault list data containing the sections to be displayed to the user.
    func build(
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter
    ) async throws -> VaultListData {
        guard !ciphers.isEmpty else { return VaultListData() }

        guard let preparedData = try await vaultListDataPreparator.prepareData(
            from: ciphers,
            collections: collections,
            folders: folders,
            filter: filter
        ) else {
            return VaultListData()
        }

        var builder = builderFactory.make(withData: preparedData)

        if filter.addTOTPGroup {
            builder = builder.addTOTPSection()
        }

        builder = try await builder
            .addFavoritesSection()
            .addTypesSection()
            .addFoldersSection()
            .addCollectionsSection()
            .addCipherDecryptionFailureIds()

        if filter.addTrashGroup {
            builder = builder.addTrashSection()
        }

        return builder.build()
    }
}
