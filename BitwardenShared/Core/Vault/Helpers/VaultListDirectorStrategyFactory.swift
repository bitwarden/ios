import BitwardenKit

protocol VaultListDirectorStrategyFactory {
    func make() -> VaultListDirectorStrategy
}

struct DefaultVaultListDirectorStrategyFactory: VaultListDirectorStrategyFactory {
    let vaultListVBuilderFactory: VaultListBuilderFactory
    let clientService: ClientService
    let errorReporter: ErrorReporter
    let stateService: StateService
    let vaultListDataArranger: VaultListDataArranger

    func make() -> VaultListDirectorStrategy {
        DefaultVaultListDirectorStrategy(
            builderFactory: vaultListVBuilderFactory,
            clientService: clientService,
            errorReporter: errorReporter,
            stateService: stateService,
            vaultListDataArranger: vaultListDataArranger
        )
    }
}
