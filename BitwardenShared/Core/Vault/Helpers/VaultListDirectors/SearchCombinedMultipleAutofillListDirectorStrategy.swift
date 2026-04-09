import BitwardenKit
import BitwardenSdk
import Combine

// MARK: - SearchVaultListDirectorStrategy

/// The director strategy to be used to build the search Autofill's passwords + Fido2 combined in multiple sections.
/// This would show two sections where passwords and Fido2 credentials are displayed in each section accordingly.
struct SearchCombinedMultipleAutofillListDirectorStrategy: VaultListSearchDirectorStrategy {
    // MARK: Properties

    /// The factory for creating vault list builders.
    let builderFactory: VaultListSectionsBuilderFactory
    /// The service used to manage syncing and updates to the user's ciphers.
    let cipherService: CipherService
    /// A helper to be used on Fido2 flows that requires user interaction and extends the capabilities
    /// of the `Fido2UserInterface` from the SDK.
    let fido2UserInterfaceHelper: Fido2UserInterfaceHelper
    /// The helper used to prepare data for the vault list builder.
    let vaultListDataPreparator: VaultListDataPreparator

    func build(
        filterPublisher: AnyPublisher<VaultListFilter, Error>,
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>> {
        try await Publishers.CombineLatest3(
            filterPublisher,
            cipherService.ciphersPublisher(),
            fido2UserInterfaceHelper.availableCredentialsForAuthenticationPublisher(),
        )
        .asyncTryMap { filter, ciphers, availableFido2Credentials in
            try await build(
                from: ciphers,
                filter: filter,
                withFido2Credentials: availableFido2Credentials,
            )
        }
        .eraseToAnyPublisher()
        .values
    }

    // MARK: Private methods

    /// Builds the vault list sections.
    /// - Parameters:
    ///   - ciphers: Ciphers to filter and include in the sections.
    ///   - filter: Filter to be used to build the sections.
    ///   - withFido2Credentials: Available Fido2 credentials to build the vault list section.
    /// - Returns: Sections to be displayed to the user.
    func build(
        from ciphers: [Cipher],
        filter: VaultListFilter,
        withFido2Credentials fido2Credentials: [CipherView]?,
    ) async throws -> VaultListData {
        guard !ciphers.isEmpty else { return VaultListData() }

        guard let preparedData = await vaultListDataPreparator.prepareSearchAutofillCombinedMultipleData(
            from: ciphers,
            filter: filter,
            withFido2Credentials: fido2Credentials,
        ) else {
            return VaultListData()
        }

        return builderFactory.make(withData: preparedData)
            .addAutofillCombinedMultipleSection(searchText: filter.searchText, rpID: filter.rpID)
            .build()
    }
}
