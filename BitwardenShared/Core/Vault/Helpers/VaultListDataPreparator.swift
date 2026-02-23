import BitwardenKit
import BitwardenSdk

/// A object that prepares vault list data for the sections builder `VaultListSectionsBuilder`.
///
/// This decrypts and process data iteratively in batches to improve time and memory on the overall
/// grouping/filtering/preparation.
protocol VaultListDataPreparator { // sourcery: AutoMockable
    /// Prepares autofill's passwords data for the vault list builder.
    /// - Parameters:
    ///   - ciphers: An array of `Cipher` objects to be processed.
    ///   - filter: A `VaultListFilter` object that defines the filtering criteria for the vault list.
    /// - Returns: An optional `VaultListPreparedData` object containing the prepared data for the vault list.
    /// Returns `nil` if the vault is empty.
    func prepareAutofillPasswordsData(
        from ciphers: [Cipher],
        filter: VaultListFilter,
    ) async -> VaultListPreparedData?

    /// Prepares autofill's data on passwords + Fido2 combined in multiple sections for the vault list builder.
    /// - Parameters:
    ///   - ciphers: An array of `Cipher` objects to be processed.
    ///   - filter: A `VaultListFilter` object that defines the filtering criteria for the vault list.
    ///   - withFido2Credentials: Available Fido2 credentials to build the vault list section.
    /// - Returns: An optional `VaultListPreparedData` object containing the prepared data for the vault list.
    /// Returns `nil` if the vault is empty.
    func prepareAutofillCombinedMultipleData(
        from ciphers: [Cipher],
        filter: VaultListFilter,
        withFido2Credentials fido2Credentials: [CipherView]?,
    ) async -> VaultListPreparedData?

    /// Prepares autofill's data on passwords + Fido2 combined in a single section for the vault list builder.
    /// - Parameters:
    ///   - ciphers: An array of `Cipher` objects to be processed.
    ///   - filter: A `VaultListFilter` object that defines the filtering criteria for the vault list.
    /// - Returns: An optional `VaultListPreparedData` object containing the prepared data for the vault list.
    /// Returns `nil` if the vault is empty.
    func prepareAutofillCombinedSingleData(
        from ciphers: [Cipher],
        filter: VaultListFilter,
    ) async -> VaultListPreparedData?

    /// Prepares data for the vault list builder.
    /// - Parameters:
    ///   - ciphers: An array of `Cipher` objects to be processed.
    ///   - collections: An array of `Collection` objects to be processed.
    ///   - folders: An array of `Folder` objects to be processed.
    ///   - filter: A `VaultListFilter` object that defines the filtering criteria for the vault list.
    /// - Returns: An optional `VaultListPreparedData` object containing the prepared data for the vault list.
    /// Returns `nil` if the vault is empty.
    func prepareData(
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter,
    ) async -> VaultListPreparedData?

    /// Prepares group data for the vault list builder.
    /// - Parameters:
    ///   - ciphers: An array of `Cipher` objects to be processed.
    ///   - collections: An array of `Collection` objects to be processed.
    ///   - folders: An array of `Folder` objects to be processed.
    ///   - filter: A `VaultListFilter` object that defines the filtering criteria for the vault list.
    /// - Returns: An optional `VaultListPreparedData` object containing the prepared data for the vault list.
    /// Returns `nil` if the vault is empty.
    func prepareGroupData(
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter,
    ) async -> VaultListPreparedData?

    /// Prepares search data for the autofill's data on passwords + Fido2 combined in multiple sections
    /// vault list builder.
    /// - Parameters:
    ///   - ciphers: An array of `Cipher` objects to be processed.
    ///   - filter: A `VaultListFilter` object that defines the filtering criteria for the vault list.
    /// - Returns: An optional `VaultListPreparedData` object containing the prepared data for the vault list.
    /// Returns `nil` if the vault is empty.
    func prepareSearchAutofillCombinedMultipleData(
        from ciphers: [Cipher],
        filter: VaultListFilter,
        withFido2Credentials fido2Credentials: [CipherView]?,
    ) async -> VaultListPreparedData?

    /// Prepares search data for the vault list builder.
    /// - Parameters:
    ///   - ciphers: An array of `Cipher` objects to be processed.
    ///   - filter: A `VaultListFilter` object that defines the filtering criteria for the vault list.
    /// - Returns: An optional `VaultListPreparedData` object containing the prepared data for the vault list.
    /// Returns `nil` if the vault is empty.
    func prepareSearchData(
        from ciphers: [Cipher],
        filter: VaultListFilter,
    ) async -> VaultListPreparedData?
}

/// Default implementation of `VaultListDataPreparator`.
struct DefaultVaultListDataPreparator: VaultListDataPreparator { // swiftlint:disable:this type_body_length
    // MARK: Properties

    /// The factory to create cipher matching helpers.
    let cipherMatchingHelperFactory: CipherMatchingHelperFactory
    /// The wrapper of the `CiphersClient` service for extended functionality.
    let ciphersClientWrapperService: CiphersClientWrapperService
    /// The service used by the application to handle encryption and decryption tasks.
    let clientService: ClientService
    /// The service to get server-specified configuration.
    let configService: ConfigService
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter
    /// The service for managing the polices for the user.
    let policyService: PolicyService
    /// The service used by the application to manage account state.
    let stateService: StateService
    /// The factory to make vault list prepared data builders.
    let vaultListPreparedDataBuilderFactory: VaultListPreparedDataBuilderFactory

    // MARK: Methods

    func prepareAutofillPasswordsData(
        from ciphers: [Cipher],
        filter: VaultListFilter,
    ) async -> VaultListPreparedData? {
        guard !ciphers.isEmpty, let uri = filter.uri else {
            return nil
        }

        let cipherMatchingHelper = await cipherMatchingHelperFactory.make(uri: uri)

        var preparedDataBuilder = vaultListPreparedDataBuilderFactory.make()

        let archiveItemsFeatureFlagEnabled: Bool = await configService.getFeatureFlag(.archiveVaultItems)

        await decryptAndProcessCiphersInBatch(
            ciphers: ciphers,
            filter: filter,
            preparedDataBuilder: preparedDataBuilder,
        ) { decryptedCipher in
            guard decryptedCipher.type.isLogin,
                  decryptedCipher.deletedDate == nil,
                  decryptedCipher.canBeUsedInBasicLoginAutofill else {
                return
            }

            let matchResult = cipherMatchingHelper.doesCipherMatch(
                cipher: decryptedCipher,
                archiveVaultItemsFF: archiveItemsFeatureFlagEnabled,
            )

            preparedDataBuilder = await preparedDataBuilder.addItem(
                withMatchResult: matchResult,
                cipher: decryptedCipher,
            )
        }

        return preparedDataBuilder.build()
    }

    func prepareAutofillCombinedMultipleData(
        from ciphers: [Cipher],
        filter: VaultListFilter,
        withFido2Credentials fido2Credentials: [CipherView]?,
    ) async -> VaultListPreparedData? {
        guard !ciphers.isEmpty, let uri = filter.uri else {
            return nil
        }

        let cipherMatchingHelper = await cipherMatchingHelperFactory.make(uri: uri)

        var preparedDataBuilder = vaultListPreparedDataBuilderFactory.make()

        let archiveItemsFeatureFlagEnabled: Bool = await configService.getFeatureFlag(.archiveVaultItems)

        await decryptAndProcessCiphersInBatch(
            ciphers: ciphers,
            filter: filter,
            preparedDataBuilder: preparedDataBuilder,
        ) { decryptedCipher in
            guard decryptedCipher.type.isLogin,
                  decryptedCipher.deletedDate == nil else {
                return
            }

            if archiveItemsFeatureFlagEnabled, decryptedCipher.isArchived {
                return
            }

            let matchResult = cipherMatchingHelper.doesCipherMatch(
                cipher: decryptedCipher,
                archiveVaultItemsFF: archiveItemsFeatureFlagEnabled,
            )
            guard matchResult != .none else {
                return
            }

            preparedDataBuilder = await preparedDataBuilder.addItemsForCombinedMultipleSections(
                decryptedCipher: decryptedCipher,
                withFido2Credentials: fido2Credentials,
            )
        }

        return preparedDataBuilder.build()
    }

    func prepareAutofillCombinedSingleData(
        from ciphers: [Cipher],
        filter: VaultListFilter,
    ) async -> VaultListPreparedData? {
        guard !ciphers.isEmpty, let uri = filter.uri else {
            return nil
        }

        let cipherMatchingHelper = await cipherMatchingHelperFactory.make(uri: uri)

        var preparedDataBuilder = vaultListPreparedDataBuilderFactory.make()

        let archiveItemsFeatureFlagEnabled: Bool = await configService.getFeatureFlag(.archiveVaultItems)

        await decryptAndProcessCiphersInBatch(
            ciphers: ciphers,
            filter: filter,
            preparedDataBuilder: preparedDataBuilder,
        ) { decryptedCipher in
            guard decryptedCipher.type.isLogin,
                  decryptedCipher.deletedDate == nil else {
                return
            }

            if archiveItemsFeatureFlagEnabled, decryptedCipher.isArchived {
                return
            }

            let matchResult = cipherMatchingHelper.doesCipherMatch(
                cipher: decryptedCipher,
                archiveVaultItemsFF: archiveItemsFeatureFlagEnabled,
            )
            guard matchResult != .none else {
                return
            }

            guard decryptedCipher.type.loginListView?.hasFido2 == true else {
                preparedDataBuilder = await preparedDataBuilder.addItem(
                    forGroup: .login,
                    with: decryptedCipher,
                )
                return
            }

            preparedDataBuilder = await preparedDataBuilder.addFido2Item(cipher: decryptedCipher)
        }

        return preparedDataBuilder.build()
    }

    func prepareData(
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter,
    ) async -> VaultListPreparedData? {
        guard !ciphers.isEmpty else {
            return nil
        }

        var preparedDataBuilder = vaultListPreparedDataBuilderFactory.make()
            .prepareFolders(folders: folders, filterType: filter.filterType)
            .prepareCollections(collections: collections, filterType: filter.filterType)

        let archiveItemsFeatureFlagEnabled: Bool = await configService.getFeatureFlag(.archiveVaultItems)

        await decryptAndProcessCiphersInBatch(
            ciphers: ciphers,
            filter: filter,
            preparedDataBuilder: preparedDataBuilder,
        ) { decryptedCipher in
            guard decryptedCipher.deletedDate == nil else {
                preparedDataBuilder = preparedDataBuilder.incrementCipherDeletedCount()
                return
            }

            if archiveItemsFeatureFlagEnabled, decryptedCipher.isArchived {
                preparedDataBuilder = preparedDataBuilder.incrementCipherArchivedCount()
                return
            }

            if filter.options.contains(.addTOTPGroup) {
                preparedDataBuilder = await preparedDataBuilder.incrementTOTPCount(cipher: decryptedCipher)
            }

            preparedDataBuilder = preparedDataBuilder
                .addCipherDecryptionFailure(cipher: decryptedCipher)
                .addFolderItem(cipher: decryptedCipher, filter: filter, folders: folders)
                .addFavoriteItem(cipher: decryptedCipher)
                .addNoFolderItem(cipher: decryptedCipher)
                .incrementCipherTypeCount(cipher: decryptedCipher)
                .incrementCollectionCount(cipher: decryptedCipher)
        }

        return preparedDataBuilder.build()
    }

    func prepareGroupData(
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter,
    ) async -> VaultListPreparedData? {
        guard !ciphers.isEmpty, let group = filter.group else {
            return nil
        }

        var preparedDataBuilder = vaultListPreparedDataBuilderFactory.make()
            .prepareFolders(folders: folders, filterType: filter.filterType)
            .prepareCollections(collections: collections, filterType: filter.filterType)

        let archiveItemsFeatureFlagEnabled: Bool = await configService.getFeatureFlag(.archiveVaultItems)

        await decryptAndProcessCiphersInBatch(
            ciphers: ciphers,
            filter: filter,
            preparedDataBuilder: preparedDataBuilder,
        ) { decryptedCipher in
            if filter.group != .trash, decryptedCipher.deletedDate != nil {
                return
            }

            if archiveItemsFeatureFlagEnabled,
               filter.group != .archive,
               filter.group != .trash,
               decryptedCipher.isArchived {
                return
            }

            if case .folder = group {
                preparedDataBuilder = preparedDataBuilder.addFolderItem(
                    cipher: decryptedCipher,
                    filter: filter,
                    folders: folders,
                )
            }

            if case .collection = group {
                preparedDataBuilder = preparedDataBuilder.incrementCollectionCount(cipher: decryptedCipher)
            }

            preparedDataBuilder = await preparedDataBuilder.addItem(forGroup: group, with: decryptedCipher)
        }

        return preparedDataBuilder.build()
    }

    func prepareSearchAutofillCombinedMultipleData(
        from ciphers: [Cipher],
        filter: VaultListFilter,
        withFido2Credentials fido2Credentials: [CipherView]?,
    ) async -> VaultListPreparedData? {
        guard !ciphers.isEmpty, let searchText = filter.searchText, !searchText.isEmpty else {
            return nil
        }

        var preparedDataBuilder = vaultListPreparedDataBuilderFactory.make()

        let archiveItemsFeatureFlagEnabled: Bool = await configService.getFeatureFlag(.archiveVaultItems)

        await decryptAndProcessCiphersInBatch(
            ciphers: ciphers,
            filter: filter,
            preparedDataBuilder: preparedDataBuilder,
            preFilter: { cipher in
                filterEncryptedCipherByDeletedAndGroup(cipher: cipher, filter: filter)
            },
            onCipher: { decryptedCipher in
                if archiveItemsFeatureFlagEnabled, decryptedCipher.isArchived {
                    return
                }

                let matchResult = decryptedCipher.matchesSearchQuery(searchText)
                guard matchResult != .none else {
                    return
                }

                preparedDataBuilder = await preparedDataBuilder.addItemsForCombinedMultipleSections(
                    decryptedCipher: decryptedCipher,
                    withFido2Credentials: fido2Credentials,
                )
            },
        )

        return preparedDataBuilder.build()
    }

    func prepareSearchData(
        from ciphers: [Cipher],
        filter: VaultListFilter,
    ) async -> VaultListPreparedData? {
        guard !ciphers.isEmpty, let searchText = filter.searchText, !searchText.isEmpty else {
            return nil
        }

        var preparedDataBuilder = vaultListPreparedDataBuilderFactory.make()

        let archiveItemsFeatureFlagEnabled: Bool = await configService.getFeatureFlag(.archiveVaultItems)

        await decryptAndProcessCiphersInBatch(
            ciphers: ciphers,
            filter: filter,
            preparedDataBuilder: preparedDataBuilder,
            preFilter: { cipher in
                filterEncryptedCipherByDeletedAndGroup(cipher: cipher, filter: filter)
            },
            onCipher: { decryptedCipher in
                if archiveItemsFeatureFlagEnabled, decryptedCipher.isArchived {
                    guard let group = filter.group, group == .archive else {
                        return
                    }
                }

                let matchResult = decryptedCipher.matchesSearchQuery(searchText)
                preparedDataBuilder = await preparedDataBuilder.addSearchResultItem(
                    withMatchResult: matchResult,
                    cipher: decryptedCipher,
                    for: filter.group,
                )
            },
        )

        return preparedDataBuilder.build()
    }

    // MARK: Private

    /// Decrypts `ciphers` in batch and perform process on each decrypted cipher of the batch.
    /// This consolidates common cipher filtering on all data preparation.
    ///
    /// - Parameters:
    ///   - ciphers: The ciphers to decrypt and process
    ///   - filter: A `VaultListFilter` object that defines the filtering criteria for the vault list
    ///   - preparedDataBuilder: The data builder that is used to prepare the ciphers data.
    ///   - preFilter: A closure to filter ciphers before decryption.
    ///   - onCipher: The action to perform on each decrypted cipher.
    func decryptAndProcessCiphersInBatch(
        ciphers: [Cipher],
        filter: VaultListFilter,
        preparedDataBuilder: VaultListPreparedDataBuilder,
        preFilter: (Cipher) throws -> Bool = { _ in true },
        onCipher: (CipherListView) async throws -> Void,
    ) async {
        let restrictedOrganizationIds: [String] = await prepareRestrictedOrganizationIds(builder: preparedDataBuilder)

        await ciphersClientWrapperService.decryptAndProcessCiphersInBatch(
            ciphers: ciphers,
            preFilter: preFilter,
            onCipher: { decryptedCipher in
                guard filter.filterType.cipherFilter(decryptedCipher),
                      decryptedCipher.passesRestrictItemTypesPolicy(restrictedOrganizationIds) else {
                    return
                }

                try await onCipher(decryptedCipher)
            },
        )
    }

    /// Filters encrypted cipher based on the vault list filter taking into consideration
    /// whether the cipher is deleted and the group filter.
    /// - Parameters:
    ///   - cipher: The cipher to filter.
    ///   - filter: The vault list filter.
    /// - Returns: `true` if the cipher passes the filter, `false` otherwise.
    func filterEncryptedCipherByDeletedAndGroup(
        cipher: Cipher,
        filter: VaultListFilter,
    ) -> Bool {
        if cipher.deletedDate != nil {
            guard let group = filter.group, group == .trash else {
                return false
            }
        }

        if let group = filter.group, group != .trash {
            return cipher.belongsToGroup(group)
        }

        return true
    }

    /// Returns the restricted organization IDs for the `.restrictItemTypes` policy and adds them
    /// to the builder.
    /// - Returns: The restricted organization IDs.
    func prepareRestrictedOrganizationIds(builder: VaultListPreparedDataBuilder) async -> [String] {
        let restrictedOrganizationIds = await policyService.getOrganizationIdsForRestricItemTypesPolicy()
        builder.prepareRestrictItemsPolicyOrganizations(restrictedOrganizationIds: restrictedOrganizationIds)
        return restrictedOrganizationIds
    }
}

// MARK: VaultListPreparedDataBuilder

private extension VaultListPreparedDataBuilder {
    func addItemsForCombinedMultipleSections(
        decryptedCipher: CipherListView,
        withFido2Credentials fido2Credentials: [CipherView]?,
    ) async -> VaultListPreparedDataBuilder {
        if let fido2Credentials,
           decryptedCipher.type.loginListView?.hasFido2 == true,
           fido2Credentials.contains(where: { $0.id == decryptedCipher.id }) {
            _ = await addFido2Item(cipher: decryptedCipher)
        }

        if decryptedCipher.canBeUsedInBasicLoginAutofill {
            _ = await addItem(
                forGroup: .login,
                with: decryptedCipher,
            )
        }
        return self
    }
} // swiftlint:disable:this file_length
