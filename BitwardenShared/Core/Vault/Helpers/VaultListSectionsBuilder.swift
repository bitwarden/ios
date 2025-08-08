import BitwardenKit
import BitwardenResources
import BitwardenSdk
import Combine
import Foundation
import OSLog

// MARK: - VaultListSectionsBuilder

/// A protocol for a vault list builder which helps build items and sections for the vault lists.
protocol VaultListSectionsBuilder { // sourcery: AutoMockable
    /// Adds a section with passwords items for Autofill vault list.
    /// - Returns: The builder for fluent code.
    func addAutofillPasswordsSection() -> VaultListSectionsBuilder

    /// Adds the list of IDs for ciphers which failed to decrypt.
    /// - Returns: The builder for fluent code.
    func addCipherDecryptionFailureIds() -> VaultListSectionsBuilder

    /// Adds a section with available collections or that correspond under the `nestedCollectionId` if passed.
    /// - Parameter nestedCollectionId: Filters the collections that are under the specified ID, if any.
    /// - Returns: The builder for fluent code.
    func addCollectionsSection(nestedCollectionId: String?) async throws -> VaultListSectionsBuilder

    /// Adds a section with favorite items.
    /// - Returns: The builder for fluent code.
    func addFavoritesSection() -> VaultListSectionsBuilder

    /// Adds a section with available folders or that correspond under the `nestedFolderId` if passed.
    /// - Parameter nestedFolderId: Filters the folders that are under the specified ID, if any.
    /// - Returns: The builder for fluent code.
    func addFoldersSection(nestedFolderId: String?) async throws -> VaultListSectionsBuilder

    /// Adds a section items belonging to a group filtered in the prepared data.
    /// - Returns: The builder for fluent code.
    func addGroupSection() -> VaultListSectionsBuilder

    /// Adds a section with TOTP items.
    /// - Returns: The builder for fluent code.
    func addTOTPSection() -> VaultListSectionsBuilder

    /// Adds a section with trash (deleted) items.
    /// - Returns: The builder for fluent code.
    func addTrashSection() -> VaultListSectionsBuilder

    /// Adds a section with items types.
    /// - Returns: The builder for fluent code.
    func addTypesSection() -> VaultListSectionsBuilder

    /// Builds and returns the vault list data.
    /// - Returns: The built vault list data.
    func build() -> VaultListData
}

extension VaultListSectionsBuilder {
    /// Adds a section with available collections.
    /// - Returns: The builder for fluent code.
    func addCollectionsSection() async throws -> VaultListSectionsBuilder {
        try await addCollectionsSection(nestedCollectionId: nil)
    }

    /// Adds a section with available folders.
    /// - Returns: The builder for fluent code.
    func addFoldersSection() async throws -> VaultListSectionsBuilder {
        try await addFoldersSection(nestedFolderId: nil)
    }
}

// MARK: - DefaultVaultListSectionsBuilder

/// The default vault list sections builder.
class DefaultVaultListSectionsBuilder: VaultListSectionsBuilder {
    // MARK: Properties

    /// The service used by the application to handle encryption and decryption tasks.
    let clientService: ClientService
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter
    /// Vault list data prepared to  be used by the builder.
    let preparedData: VaultListPreparedData
    /// The vault list data to build.
    private var vaultListData = VaultListData()

    // MARK: Init

    /// Initializes a `DefaultVaultListSectionsBuilder`.
    /// - Parameters:
    ///   - clientService: The service used by the application to handle encryption and decryption tasks.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - preparedData: `VaultListPreparedData` to be used as input to build the sections where the caller
    ///   decides which to include depending on the builder methods called.
    init(
        clientService: ClientService,
        errorReporter: ErrorReporter,
        withData preparedData: VaultListPreparedData
    ) {
        self.clientService = clientService
        self.errorReporter = errorReporter
        self.preparedData = preparedData
    }

    // MARK: Methods

    func addCipherDecryptionFailureIds() -> VaultListSectionsBuilder {
        vaultListData.cipherDecryptionFailureIds = preparedData.cipherDecryptionFailureIds
        return self
    }

    func addAutofillPasswordsSection() -> VaultListSectionsBuilder {
        guard !preparedData.exactMatchItems.isEmpty || !preparedData.fuzzyMatchItems.isEmpty else {
            return self
        }

        let matchingItems = preparedData.exactMatchItems.sorted(using: VaultListItem.defaultSortDescriptor)
            + preparedData.fuzzyMatchItems.sorted(using: VaultListItem.defaultSortDescriptor)

        vaultListData.sections.append(VaultListSection(
            id: "AutofillPasswords",
            items: matchingItems,
            name: ""
        ))
        return self
    }

    func addCollectionsSection(nestedCollectionId: String? = nil) async throws -> VaultListSectionsBuilder {
        guard !preparedData.collections.isEmpty else {
            return self
        }

        let collectionTree = try await clientService.vault().collections()
            .decryptList(collections: preparedData.collections)
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
                    preparedData.collectionsCount[collectionId, default: 0]
                )
            )
        }

        if !collectionItems.isEmpty {
            vaultListData.sections.append(
                VaultListSection(id: "Collections", items: collectionItems, name: Localizations.collections)
            )
        }
        return self
    }

    func addFavoritesSection() -> VaultListSectionsBuilder {
        if !preparedData.favorites.isEmpty {
            vaultListData.sections.append(VaultListSection(
                id: "Favorites",
                items: preparedData.favorites.sorted(using: VaultListItem.defaultSortDescriptor),
                name: Localizations.favorites
            ))
        }
        return self
    }

    func addFoldersSection(nestedFolderId: String? = nil) async throws -> VaultListSectionsBuilder {
        // swiftlint:disable:previous function_body_length
        let folderTree = try await clientService.vault().folders()
            .decryptList(folders: preparedData.folders)
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
                    ), preparedData.foldersCount[folderId, default: 0])
                )
            }

        // Add no folder to folders item if needed.
        let showNoFolderCipherGroup = preparedData.collections.isEmpty
            && preparedData.noFolderItems.count < Constants.noFolderListSize
        if !showNoFolderCipherGroup, !preparedData.noFolderItems.isEmpty {
            foldersVaultListItems.append(
                VaultListItem(
                    id: "NoFolderFolderItem",
                    itemType: .group(.noFolder, preparedData.noFolderItems.count)
                )
            )
        }

        if !foldersVaultListItems.isEmpty {
            vaultListData.sections.append(
                VaultListSection(id: "Folders", items: foldersVaultListItems, name: Localizations.folders)
            )
        }

        if showNoFolderCipherGroup, !preparedData.noFolderItems.isEmpty {
            vaultListData.sections.append(VaultListSection(
                id: "NoFolder",
                items: preparedData.noFolderItems.sorted(using: VaultListItem.defaultSortDescriptor),
                name: Localizations.folderNone
            ))
        }

        return self
    }

    func addGroupSection() -> VaultListSectionsBuilder {
        if !preparedData.groupItems.isEmpty {
            vaultListData.sections.append(
                VaultListSection(
                    id: "Items",
                    items: preparedData
                        .groupItems
                        .sorted(using: VaultListItem.defaultSortDescriptor),
                    name: Localizations.items
                )
            )
        }
        return self
    }

    func addTOTPSection() -> VaultListSectionsBuilder {
        if preparedData.totpItemsCount > 0 {
            vaultListData.sections.append(VaultListSection(
                id: "TOTP",
                items: [
                    VaultListItem(
                        id: "Types.VerificationCodes",
                        itemType: .group(.totp, preparedData.totpItemsCount)
                    ),
                ],
                name: Localizations.totp
            ))
        }
        return self
    }

    func addTrashSection() -> VaultListSectionsBuilder {
        let ciphersTrashItem = VaultListItem(id: "Trash", itemType: .group(.trash, preparedData.ciphersDeletedCount))
        vaultListData.sections.append(
            VaultListSection(id: "Trash", items: [ciphersTrashItem], name: Localizations.trash)
        )
        return self
    }

    func addTypesSection() -> VaultListSectionsBuilder {
        var types = [
            VaultListItem(
                id: "Types.Logins",
                itemType: .group(.login, preparedData.countPerCipherType[.login, default: 0])
            ),
        ]

        let cardCount = preparedData.countPerCipherType[.card, default: 0]
        if preparedData.restrictedOrganizationIds.isEmpty || cardCount != 0 {
            types.append(
                VaultListItem(
                    id: "Types.Cards",
                    itemType: .group(.card, cardCount)
                ),
            )
        }

        types.append(
            contentsOf: [
                VaultListItem(
                    id: "Types.Identities",
                    itemType: .group(.identity, preparedData.countPerCipherType[.identity, default: 0])
                ),
                VaultListItem(
                    id: "Types.SecureNotes",
                    itemType: .group(.secureNote, preparedData.countPerCipherType[.secureNote, default: 0])
                ),
                VaultListItem(
                    id: "Types.SSHKeys",
                    itemType: .group(.sshKey, preparedData.countPerCipherType[.sshKey, default: 0])
                ),
            ]
        )

        vaultListData.sections.append(VaultListSection(id: "Types", items: types, name: Localizations.types))
        return self
    }

    func build() -> VaultListData {
        vaultListData
    }
}

// MARK: - VaultListPreparedData

/// Metadata helper object to hold temporary prepared (grouped, filtered, counted) data
/// the builder can then use to build the list sections.
struct VaultListPreparedData {
    var cipherDecryptionFailureIds: [Uuid] = []
    var ciphersDeletedCount: Int = 0
    var collections: [Collection] = []
    var collectionsCount: [Uuid: Int] = [:]
    var countPerCipherType: [CipherType: Int] = [
        .card: 0,
        .identity: 0,
        .login: 0,
        .secureNote: 0,
        .sshKey: 0,
    ]
    var exactMatchItems: [VaultListItem] = []
    var favorites: [VaultListItem] = []
    var folders: [Folder] = []
    var foldersCount: [Uuid: Int] = [:]
    var fuzzyMatchItems: [VaultListItem] = []
    var groupItems: [VaultListItem] = []
    var noFolderItems: [VaultListItem] = []
    /// Organization Ids with `.restrictItemTypes` policy enabled.
    var restrictedOrganizationIds: [String] = []
    var totpItemsCount: Int = 0
}
