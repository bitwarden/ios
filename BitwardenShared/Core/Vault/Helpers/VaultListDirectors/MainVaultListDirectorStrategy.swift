import BitwardenKit
import BitwardenSdk
import Combine
import OSLog

// MARK: - MainVaultListDirectorStrategy

/// The director strategy to be used to build the main vault sections.
struct MainVaultListDirectorStrategy: VaultListDirectorStrategy {
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
    ///   - filter: Fitler to be used to build the sections.
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

        guard var vaultListMetadata = try await vaultListDataArranger.arrangeMetadata(
            from: ciphers,
            collections: collections,
            folders: folders,
            filter: filter
        ) else {
            return []
        }

        var builder = builderFactory.make()

        if filter.addTOTPGroup {
            builder = builder.addTOTPSection(from: &vaultListMetadata)
        }

        builder = try await builder
            .addFavoritesSection(from: &vaultListMetadata)
            .addTypesSection(from: &vaultListMetadata)
            .addFoldersSection(from: &vaultListMetadata)
            .addCollectionsSection(from: &vaultListMetadata)

        if filter.addTrashGroup {
            builder = builder.addTrashSection(from: &vaultListMetadata)
        }

        return builder.build()
    }
}
