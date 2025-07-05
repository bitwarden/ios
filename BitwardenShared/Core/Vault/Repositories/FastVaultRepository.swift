import BitwardenKit
import BitwardenSdk
import Combine
import Foundation
import OSLog

class FastVaultRepository: DefaultVaultRepository {
    let vaultListDirectorStrategyFactory: VaultListDirectorStrategyFactory

    init(
        cipherService: CipherService,
        clientService: ClientService,
        collectionService: CollectionService,
        configService: ConfigService,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        folderService: FolderService,
        organizationService: OrganizationService,
        policyService: PolicyService,
        settingsService: SettingsService,
        stateService: StateService,
        syncService: SyncService,
        timeProvider: TimeProvider,
        vaultListDirectorStrategyFactory: VaultListDirectorStrategyFactory,
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.vaultListDirectorStrategyFactory = vaultListDirectorStrategyFactory
        super.init(
            cipherService: cipherService,
            clientService: clientService,
            collectionService: collectionService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            folderService: folderService,
            organizationService: organizationService,
            policyService: policyService,
            settingsService: settingsService,
            stateService: stateService,
            syncService: syncService,
            timeProvider: timeProvider,
            vaultTimeoutService: vaultTimeoutService
        )
    }

    override func vaultListPublisher(
        filter: VaultListFilter
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListSection], any Error>> {
        try await vaultListDirectorStrategyFactory
            .make(filter: filter)
            .build(filter: filter)
    }
}
