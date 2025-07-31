import BitwardenKit

// MARK: - VaultListDirectorStrategyFactory

/// Factory to create `VaultListDirectorStrategy`.
protocol VaultListDirectorStrategyFactory { // sourcery: AutoMockable
    /// Makes a `VaultListDirectorStrategy` from the specified filter.
    func make(filter: VaultListFilter) -> VaultListDirectorStrategy
}

// MARK: - DefaultVaultListDirectorStrategyFactory

/// Default implementation of `VaultListDirectorStrategyFactory`.
struct DefaultVaultListDirectorStrategyFactory: VaultListDirectorStrategyFactory {
    /// The service used to manage syncing and updates to the user's ciphers.
    let cipherService: CipherService
    /// The service for managing the collections for the user.
    let collectionService: CollectionService
    /// The service used to manage syncing and updates to the user's folders.
    let folderService: FolderService
    /// The factory for creating vault list builders.
    let vaultListBuilderFactory: VaultListSectionsBuilderFactory
    /// The helper used to prepare data for the vault list builder.
    let vaultListDataPreparator: VaultListDataPreparator

    func make(filter: VaultListFilter) -> VaultListDirectorStrategy {
        if filter.mode == .passwords {
            return PasswordsAutofillVaultListDirectorStrategy(
                builderFactory: vaultListBuilderFactory,
                cipherService: cipherService,
                vaultListDataPreparator: vaultListDataPreparator
            )
        }

        if filter.group != nil {
            return MainVaultListGroupDirectorStrategy(
                builderFactory: vaultListBuilderFactory,
                cipherService: cipherService,
                collectionService: collectionService,
                folderService: folderService,
                vaultListDataPreparator: vaultListDataPreparator
            )
        }

        return MainVaultListDirectorStrategy(
            builderFactory: vaultListBuilderFactory,
            cipherService: cipherService,
            collectionService: collectionService,
            folderService: folderService,
            vaultListDataPreparator: vaultListDataPreparator
        )
    }
}
