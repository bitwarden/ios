import BitwardenKit
import BitwardenSdk
import Combine
import Foundation
import OSLog

class FastVaultRepository: DefaultVaultRepository {
    let vaultListDirectorStrategy: VaultListDirectorStrategy

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
        vaultListDirectorStrategy: VaultListDirectorStrategy,
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.vaultListDirectorStrategy = vaultListDirectorStrategy
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
        try await Publishers.CombineLatest3(
            cipherService.ciphersPublisher(),
            collectionService.collectionsPublisher(),
            folderService.foldersPublisher()
        )
        .asyncTryMap { [weak self] ciphers, collections, folders in
            guard let self else {
                return []
            }
            return try await vaultListDirectorStrategy.build(
                from: ciphers,
                collections: collections,
                folders: folders,
                filter: filter
            )
        }
        .eraseToAnyPublisher()
        .values
    }
}
