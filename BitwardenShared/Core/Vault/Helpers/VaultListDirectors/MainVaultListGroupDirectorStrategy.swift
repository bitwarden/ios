import BitwardenKit
import BitwardenSdk
import Combine
import OSLog

// MARK: - MainVaultListGroupDirectorStrategy

/// The director strategy to be used to build the main vault sections filtered by group.
struct MainVaultListGroupDirectorStrategy: VaultListDirectorStrategy {
    // MARK: Properties

    /// The factory for creating vault list builders.
    let builderFactory: VaultListBuilderFactory
    /// The service used to manage syncing and updates to the user's ciphers.
    let cipherService: CipherService
    /// The service used by the application to handle encryption and decryption tasks.
    let clientService: ClientService
    /// The service for managing the collections for the user.
    let collectionService: CollectionService
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter
    /// The service used to manage syncing and updates to the user's folders.
    let folderService: FolderService
    /// The service used by the application to manage account state.
    let stateService: StateService
    /// The helper used to arrange data for the vault list builder.
    let vaultListDataArranger: VaultListDataArranger

    func build(
        filter: VaultListFilter
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListSection], Error>> {
        try await Publishers.CombineLatest3(
            cipherService.ciphersPublisher(),
            collectionService.collectionsPublisher(),
            folderService.foldersPublisher()
        )
        .asyncTryMap { ciphers, collections, folders in
            try await self.build(from: ciphers, collections: collections, folders: folders, filter: filter)
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

        let log = OSLog(subsystem: "com.8bit.bitwarden", category: .pointsOfInterest)
        os_signpost(.begin, log: log, name: StaticString("VaultListSections"))
        defer {
            os_signpost(.end, log: log, name: StaticString("VaultListSections"))
        }

        guard let vaultListMetadata = try await vaultListDataArranger.arrangeGroupMetadata(
            from: ciphers,
            collections: collections,
            folders: folders,
            filter: filter
        ) else {
            return []
        }

        var builder = builderFactory.make()
        if case let .folder(id, _) = filter.group {
            builder = try await builder.addFoldersSection(from: vaultListMetadata, nestedFolderId: id)
        }
        if case let .collection(id, _, _) = filter.group {
            builder = try await builder.addCollectionsSection(from: vaultListMetadata, nestedCollectionId: id)
        }
        return try await builder
            .addGroupSection(from: vaultListMetadata)
            .build()
    }
}
