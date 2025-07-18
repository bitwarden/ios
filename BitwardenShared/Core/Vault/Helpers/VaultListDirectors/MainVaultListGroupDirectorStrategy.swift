import BitwardenKit
import BitwardenSdk
import Combine
import OSLog

// MARK: - MainVaultListGroupDirectorStrategy

/// The director strategy to be used to build the main vault sections filtered by group.
struct MainVaultListGroupDirectorStrategy: VaultListDirectorStrategy {
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
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListSection], Error>> {
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
    /// - Returns: Sections to be displayed to the user.
    func build(
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter
    ) async throws -> [VaultListSection] {
        guard !ciphers.isEmpty else { return [] }

        guard let preparedGroupData = try await vaultListDataPreparator.prepareGroupData(
            from: ciphers,
            collections: collections,
            folders: folders,
            filter: filter
        ) else {
            return []
        }

        var builder = builderFactory.make(withData: preparedGroupData)
        if case let .folder(id, _) = filter.group {
            builder = try await builder.addFoldersSection(nestedFolderId: id)
        }
        if case let .collection(id, _, _) = filter.group {
            builder = try await builder.addCollectionsSection(nestedCollectionId: id)
        }
        return builder
            .addGroupSection()
            .build()
    }
}
