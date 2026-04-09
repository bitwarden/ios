import BitwardenKit
import BitwardenSdk
import Combine

// MARK: - CombinedSingleAutofillVaultListDirectorStrategy

/// The director strategy to be used to build the Autofill's passwords + Fido2 combined single section.
/// This would show a single section where both passwords and Fido2 credentials are displayed.
struct CombinedSingleAutofillVaultListDirectorStrategy: VaultListDirectorStrategy {
    // MARK: Properties

    /// The factory for creating vault list builders.
    let builderFactory: VaultListSectionsBuilderFactory
    /// The service used to manage syncing and updates to the user's ciphers.
    let cipherService: CipherService
    /// The helper used to prepare data for the vault list builder.
    let vaultListDataPreparator: VaultListDataPreparator

    func build(
        filter: VaultListFilter,
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>> {
        try await cipherService.ciphersPublisher()
            .asyncTryMap { ciphers in
                try await build(from: ciphers, filter: filter)
            }
            .eraseToAnyPublisher()
            .values
    }

    // MARK: Private methods

    /// Builds the vault list sections.
    /// - Parameters:
    ///   - ciphers: Ciphers to filter and include in the sections.
    ///   - filter: Filter to be used to build the sections.
    /// - Returns: Sections to be displayed to the user.
    func build(
        from ciphers: [Cipher],
        filter: VaultListFilter,
    ) async throws -> VaultListData {
        guard let preparedData = await vaultListDataPreparator.prepareAutofillCombinedSingleData(
            from: ciphers,
            filter: filter,
        ) else {
            return VaultListData()
        }

        return builderFactory.make(withData: preparedData)
            .addAutofillCombinedSingleSection()
            .build()
    }
}
