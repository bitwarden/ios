import BitwardenKit

// MARK: - VaultListDirectorStrategyFactory

/// Factory to create `VaultListDirectorStrategy`.
/// `VaultListDirectorStrategy` implementations should never be created directly - one should always
/// create them by using this factory.
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
    /// A helper to be used on Fido2 flows that requires user interaction and extends the capabilities
    /// of the `Fido2UserInterface` from the SDK.
    let fido2UserInterfaceHelper: Fido2UserInterfaceHelper
    /// The service used to manage syncing and updates to the user's folders.
    let folderService: FolderService
    /// The factory for creating vault list builders.
    let vaultListBuilderFactory: VaultListSectionsBuilderFactory
    /// The helper used to prepare data for the vault list builder.
    let vaultListDataPreparator: VaultListDataPreparator

    func make(filter: VaultListFilter) -> VaultListDirectorStrategy {
        switch filter.mode {
        case .combinedMultipleSections:
            return CombinedMultipleAutofillVaultListDirectorStrategy(
                builderFactory: vaultListBuilderFactory,
                cipherService: cipherService,
                fido2UserInterfaceHelper: fido2UserInterfaceHelper,
                vaultListDataPreparator: vaultListDataPreparator,
            )
        case .combinedSingleSection:
            return CombinedSingleAutofillVaultListDirectorStrategy(
                builderFactory: vaultListBuilderFactory,
                cipherService: cipherService,
                vaultListDataPreparator: vaultListDataPreparator,
            )
        case .passwords:
            return PasswordsAutofillVaultListDirectorStrategy(
                builderFactory: vaultListBuilderFactory,
                cipherService: cipherService,
                vaultListDataPreparator: vaultListDataPreparator,
            )
        default:
            if filter.group != nil {
                return MainVaultListGroupDirectorStrategy(
                    builderFactory: vaultListBuilderFactory,
                    cipherService: cipherService,
                    collectionService: collectionService,
                    folderService: folderService,
                    vaultListDataPreparator: vaultListDataPreparator,
                )
            }

            return MainVaultListDirectorStrategy(
                builderFactory: vaultListBuilderFactory,
                cipherService: cipherService,
                collectionService: collectionService,
                folderService: folderService,
                vaultListDataPreparator: vaultListDataPreparator,
            )
        }
    }
}
