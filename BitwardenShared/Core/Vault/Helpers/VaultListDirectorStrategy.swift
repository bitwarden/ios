import BitwardenKit
import BitwardenSdk
import OSLog

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
    // MARK: Properties

    /// The factory for creating vault list builders.
    let builderFactory: VaultListBuilderFactory
    /// The service used by the application to handle encryption and decryption tasks.
    let clientService: ClientService
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter
    /// The service used by the application to manage account state.
    let stateService: StateService
    /// The helper used to arrange data for the vault list builder.
    let vaultListDataArranger: VaultListDataArranger

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

        guard var vaultListMetadata = try await vaultListDataArranger.arrangeMetadata2(
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

// MARK: - VualtListBuilderMetadata

/// Metadata helper object to hold temporary data the builder can then use to build the list sections.
struct VualtListBuilderMetadata {
    var ciphersDeletedCount: Int = 0
    var collections: [Collection] = []
    var collectionsCount: [Uuid: Int] = [:]
    var countPerCipherType: [BitwardenSdk.CipherType: Int] = [
        .card: 0,
        .identity: 0,
        .login: 0,
        .secureNote: 0,
        .sshKey: 0,
    ]
    var favorites: [VaultListItem] = []
    var folders: [Folder] = []
    var foldersCount: [Uuid: Int] = [:]
    var noFolderItems: [VaultListItem] = []
    var totpItemsCount: Int = 0
}

// MARK: - VaultListDirectorOptions

struct VaultListDirectorOptions {

}
