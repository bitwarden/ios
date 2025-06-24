import BitwardenKit

protocol VaultListDirectorStrategyFactory {
    func make(filter: VaultListFilter) -> VaultListDirectorStrategy
}

struct DefaultVaultListDirectorStrategyFactory: VaultListDirectorStrategyFactory {
    let vaultListBuilderFactory: VaultListBuilderFactory
    let cipherService: CipherService
    let clientService: ClientService
    let collectionService: CollectionService
    let errorReporter: ErrorReporter
    let folderService: FolderService
    let stateService: StateService
    let vaultListDataArranger: VaultListDataArranger

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
                vaultListDataArranger: vaultListDataArranger
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
            vaultListDataArranger: vaultListDataArranger
        )
    }
}
