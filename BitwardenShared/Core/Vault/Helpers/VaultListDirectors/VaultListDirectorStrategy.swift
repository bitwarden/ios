import BitwardenKit
import BitwardenSdk
import Combine

// MARK: - VaultListDirectorStrategy

protocol VaultListDirectorStrategy {
    /// Builds the vault list sections.
    /// - Parameters:
    ///   - filter: Filter to be used to build the sections.
    /// - Returns: Sections to be displayed to the user.
    func build(
        filter: VaultListFilter
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListSection], Error>>
}

// MARK: - VaultListBuilderMetadata

/// Metadata helper object to hold temporary data the builder can then use to build the list sections.
struct VaultListBuilderMetadata {
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
    var groupItems: [VaultListItem] = []
    var noFolderItems: [VaultListItem] = []
    var totpItemsCount: Int = 0
}
