import BitwardenKit
import BitwardenSdk
import Combine
import Foundation
import OSLog

// MARK: - VaultListBuilderFactory

/// A factory protocol to make vault list builders.
protocol VaultListBuilderFactory {
    func make() -> VaultListBuilder
}

// MARK: - DefaultVaultListBuilderFactory

/// The default implemetnation of `VaultListBuilderFactory`.
struct DefaultVaultListBuilderFactory: VaultListBuilderFactory {
    let clientService: ClientService
    let errorReporter: ErrorReporter

    func make() -> VaultListBuilder {
        DefaultVaultListBuilder(clientService: clientService, errorReporter: errorReporter)
    }
}

// MARK: - VaultListBuilder

/// A protocol for a vault list builder which helps build items and sections for the vault lists.
protocol VaultListBuilder {
    func addTrashSection(
        from tempData: VaultListBuilderMetadata
    ) -> VaultListBuilder

    func addCollectionsSection(
        from tempData: VaultListBuilderMetadata,
        nestedCollectionId: String?
    ) async throws -> VaultListBuilder

    func addFavoritesSection(
        from tempData: VaultListBuilderMetadata
    ) -> VaultListBuilder

    func addFoldersSection(
        from tempData: VaultListBuilderMetadata,
        nestedFolderId: String?
    ) async throws -> VaultListBuilder

    func addGroupSection(
        from tempData: VaultListBuilderMetadata
    ) async throws -> VaultListBuilder

    func addTOTPSection(
        from tempData: VaultListBuilderMetadata
    ) -> VaultListBuilder

    func addTypesSection(
        from tempData: VaultListBuilderMetadata
    ) -> VaultListBuilder

    func build() -> [VaultListSection]
}

extension VaultListBuilder {
    func addCollectionsSection(
        from tempData: VaultListBuilderMetadata
    ) async throws -> VaultListBuilder {
        try await addCollectionsSection(from: tempData, nestedCollectionId: nil)
    }

    func addFoldersSection(
        from tempData: VaultListBuilderMetadata
    ) async throws -> VaultListBuilder {
        try await addFoldersSection(from: tempData, nestedFolderId: nil)
    }
}

// MARK: - DefaultVaultListBuilder

/// The default vault list builder.
class DefaultVaultListBuilder: VaultListBuilder {
    // MARK: Properties

    let clientService: ClientService
    let errorReporter: ErrorReporter

    var sections: [VaultListSection] = []

    // MARK: Init

    init(clientService: ClientService, errorReporter: ErrorReporter) {
        self.clientService = clientService
        self.errorReporter = errorReporter
    }

    // MARK: Methods

    func addTrashSection(
        from tempData: VaultListBuilderMetadata
    ) -> VaultListBuilder {
        let ciphersTrashItem = VaultListItem(id: "Trash", itemType: .group(.trash, tempData.ciphersDeletedCount))
        sections.append(VaultListSection(id: "Trash", items: [ciphersTrashItem], name: Localizations.trash))
        return self
    }

    func addCollectionsSection(
        from tempData: VaultListBuilderMetadata,
        nestedCollectionId: String? = nil
    ) async throws -> VaultListBuilder {
        guard !tempData.collections.isEmpty else {
            return self
        }

        let collectionTree = try await clientService.vault().collections()
            .decryptList(collections: tempData.collections)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .asNestedNodes()

        let nestedCollections = if let nestedCollectionId {
            collectionTree.getTreeNodeObject(with: nestedCollectionId)?.children
        } else {
            collectionTree.rootNodes
        }

        guard let nestedCollections else { return self }

        let collectionItems: [VaultListItem] = nestedCollections.compactMap { collectionNode in
            let collection = collectionNode.node
            guard let collectionId = collection.id else {
                self.errorReporter.log(
                    error: BitwardenError.dataError("Received a collection from the API with a missing ID.")
                )
                return nil
            }
            return VaultListItem(
                id: collectionId,
                itemType: .group(
                    .collection(id: collectionId, name: collectionNode.name, organizationId: collection.organizationId),
                    tempData.collectionsCount[collectionId, default: 0]
                )
            )
        }

        sections.append(VaultListSection(id: "Collections", items: collectionItems, name: Localizations.collections))
        return self
    }

    func addFavoritesSection(
        from tempData: VaultListBuilderMetadata
    ) -> VaultListBuilder {
        sections.append(VaultListSection(
            id: "Favorites",
            items: tempData.favorites
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending },
            name: Localizations.favorites
        ))
        return self
    }

    func addFoldersSection(
        from tempData: VaultListBuilderMetadata,
        nestedFolderId: String? = nil
    ) async throws -> VaultListBuilder {
        guard !tempData.folders.isEmpty else {
            return self
        }

        let folderTree = try await clientService.vault().folders()
            .decryptList(folders: tempData.folders)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .asNestedNodes()

        let folders: [TreeNode<FolderView>]? = if let nestedFolderId {
            folderTree.getTreeNodeObject(with: nestedFolderId)?.children
        } else {
            folderTree.rootNodes
        }

        guard let folders else { return self }

        var foldersVaultListItems: [VaultListItem] = folders
            .compactMap { folderNode in
                guard let folderId = folderNode.node.id else {
                    self.errorReporter.log(
                        error: BitwardenError.dataError("Received a folder from the API with a missing ID.")
                    )
                    return nil
                }
                return VaultListItem(
                    id: folderId,
                    itemType: .group(.folder(
                        id: folderId,
                        name: folderNode.name
                    ), tempData.foldersCount[folderId, default: 0])
                )
            }

        // Add no folder to folders item if needed.
        let showNoFolderCipherGroup = tempData.collections.isEmpty
            && tempData.noFolderItems.count < Constants.noFolderListSize
        if !showNoFolderCipherGroup, !tempData.noFolderItems.isEmpty {
            foldersVaultListItems.append(
                VaultListItem(
                    id: "NoFolderFolderItem",
                    itemType: .group(.noFolder, tempData.noFolderItems.count)
                )
            )
        }

        if !foldersVaultListItems.isEmpty {
            sections.append(VaultListSection(id: "Folders", items: foldersVaultListItems, name: Localizations.folders))
        }

        if showNoFolderCipherGroup, !tempData.noFolderItems.isEmpty {
            sections.append(VaultListSection(
                id: "NoFolder",
                items: tempData.noFolderItems,
                name: Localizations.folderNone
            ))
        }

        return self
    }

    func addGroupSection(
        from tempData: VaultListBuilderMetadata
    ) async throws -> VaultListBuilder {
        if !tempData.groupItems.isEmpty {
            sections.append(VaultListSection(id: "Items", items: tempData.groupItems, name: Localizations.items))
        }
        return self
    }

    func addTOTPSection(
        from tempData: VaultListBuilderMetadata
    ) -> VaultListBuilder {
        sections.append(VaultListSection(
            id: "TOTP",
            items: tempData.totpItemsCount > 0
                ? [
                    VaultListItem(
                        id: "Types.VerificationCodes",
                        itemType: .group(.totp, tempData.totpItemsCount)
                    ),
                ] : [],
            name: Localizations.totp
        ))
        return self
    }

    func addTypesSection(
        from tempData: VaultListBuilderMetadata
    ) -> VaultListBuilder {
        let types = [
            VaultListItem(
                id: "Types.Logins",
                itemType: .group(.login, tempData.countPerCipherType[.login, default: 0])
            ),
            VaultListItem(
                id: "Types.Cards",
                itemType: .group(.card, tempData.countPerCipherType[.card, default: 0])
            ),
            VaultListItem(
                id: "Types.Identities",
                itemType: .group(.identity, tempData.countPerCipherType[.identity, default: 0])
            ),
            VaultListItem(
                id: "Types.SecureNotes",
                itemType: .group(.secureNote, tempData.countPerCipherType[.secureNote, default: 0])
            ),
            VaultListItem(
                id: "Types.SSHKeys",
                itemType: .group(.sshKey, tempData.countPerCipherType[.sshKey, default: 0])
            ),
        ]

        sections.append(VaultListSection(id: "Types", items: types, name: Localizations.types))
        return self
    }

    func build() -> [VaultListSection] {
        sections
    }
}
