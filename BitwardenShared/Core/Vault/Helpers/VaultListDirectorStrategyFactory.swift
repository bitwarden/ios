import BitwardenKit

// MARK: - VaultListDirectorStrategyFactory

/// Factory to create `VaultListDirectorStrategy`.
protocol VaultListDirectorStrategyFactory {
    /// Makes a `VaultListDirectorStrategy` from the specified filter.
    func make(filter: VaultListFilter) -> VaultListDirectorStrategy
}

// MARK: - DefaultVaultListDirectorStrategyFactory

/// Default implementation of `VaultListDirectorStrategyFactory`.
struct DefaultVaultListDirectorStrategyFactory: VaultListDirectorStrategyFactory {
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
    /// The factory for creating vault list builders.
    let vaultListBuilderFactory: VaultListSectionsBuilderFactory
    /// The helper used to prepare data for the vault list builder.
    let vaultListDataPreparator: VaultListDataPreparator

    func make(filter: VaultListFilter) -> VaultListDirectorStrategy {
        if filter.group != nil {
            return MainVaultListGroupDirectorStrategy(
                builderFactory: vaultListBuilderFactory,
                cipherService: cipherService,
                clientService: clientService,
                collectionService: collectionService,
                errorReporter: errorReporter,
                folderService: folderService,
                stateService: stateService,
                vaultListDataPreparator: vaultListDataPreparator
            )
        }

        return MainVaultListDirectorStrategy(
            builderFactory: vaultListBuilderFactory,
            cipherService: cipherService,
            clientService: clientService,
            collectionService: collectionService,
            errorReporter: errorReporter,
            folderService: folderService,
            stateService: stateService,
            vaultListDataPreparator: vaultListDataPreparator
        )
    }
}
