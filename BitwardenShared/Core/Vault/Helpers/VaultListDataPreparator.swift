import BitwardenKit
import BitwardenSdk

/// A object that prepares vault list data for the sections builder `VaultListSectionsBuilder`.
///
/// This decrypts and process data iteratively in batches to improve time and memory on the overall
/// grouping/filtering/preparation.
protocol VaultListDataPreparator { // sourcery: AutoMockable
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
        filter: VaultListFilter
    ) async throws -> VaultListPreparedData?

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
        filter: VaultListFilter
    ) async throws -> VaultListPreparedData?

    /// Prepares autofill's passwords data for the vault list builder.
    /// - Parameters:
    ///   - ciphers: An array of `Cipher` objects to be processed.
    ///   - filter: A `VaultListFilter` object that defines the filtering criteria for the vault list.
    /// - Returns: An optional `VaultListPreparedData` object containing the prepared data for the vault list.
    /// Returns `nil` if the vault is empty.
    func prepareAutofillPasswordsData(
        from ciphers: [Cipher],
        filter: VaultListFilter
    ) async throws -> VaultListPreparedData?
}

/// Default implementation of `VaultListDataPreparator`.
struct DefaultVaultListDataPreparator: VaultListDataPreparator {
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

    func prepareData(
        from ciphers: [Cipher],
        collections: [Collection],
        folders: [Folder],
        filter: VaultListFilter
    ) async throws -> VaultListPreparedData? {
        guard !ciphers.isEmpty else {
            return nil
        }

        var preparedDataBuilder = vaultListPreparedDataBuilderFactory.make()
        let restrictedOrganizationIds = await prepareRestrictedOrganizationIds(builder: preparedDataBuilder)

        preparedDataBuilder = preparedDataBuilder
            .prepareFolders(folders: folders, filterType: filter.filterType)
            .prepareCollections(collections: collections, filterType: filter.filterType)

        await ciphersClientWrapperService.decryptAndProcessCiphersInBatch(
            ciphers: ciphers
        ) { decryptedCipher in
            guard filter.filterType.cipherFilter(decryptedCipher),
                  decryptedCipher.passesRestrictItemTypesPolicy(restrictedOrganizationIds) else {
                return
            }

            guard decryptedCipher.deletedDate == nil else {
                preparedDataBuilder = preparedDataBuilder.incrementCipherDeletedCount()
                return
            }

            if filter.addTOTPGroup {
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
        filter: VaultListFilter
    ) async throws -> VaultListPreparedData? {
        guard !ciphers.isEmpty, let group = filter.group else {
            return nil
        }

        var preparedDataBuilder = vaultListPreparedDataBuilderFactory.make()
        let restrictedOrganizationIds: [String] = await prepareRestrictedOrganizationIds(builder: preparedDataBuilder)

        preparedDataBuilder = preparedDataBuilder
            .prepareFolders(folders: folders, filterType: filter.filterType)
            .prepareCollections(collections: collections, filterType: filter.filterType)

        await ciphersClientWrapperService.decryptAndProcessCiphersInBatch(
            ciphers: ciphers
        ) { decryptedCipher in
            guard filter.filterType.cipherFilter(decryptedCipher),
                  decryptedCipher.passesRestrictItemTypesPolicy(restrictedOrganizationIds) else {
                return
            }

            if filter.group != .trash, decryptedCipher.deletedDate != nil {
                return
            }

            if case .folder = group {
                preparedDataBuilder = preparedDataBuilder.addFolderItem(
                    cipher: decryptedCipher,
                    filter: filter,
                    folders: folders
                )
            }

            if case .collection = group {
                preparedDataBuilder = preparedDataBuilder.incrementCollectionCount(cipher: decryptedCipher)
            }

            preparedDataBuilder = await preparedDataBuilder.addItem(forGroup: group, with: decryptedCipher)
        }

        return preparedDataBuilder.build()
    }

    func prepareAutofillPasswordsData(
        from ciphers: [Cipher],
        filter: VaultListFilter
    ) async throws -> VaultListPreparedData? {
        guard !ciphers.isEmpty, let uri = filter.uri else {
            return nil
        }

        let cipherMatchingHelper = await cipherMatchingHelperFactory.make(uri: uri)

        var preparedDataBuilder = vaultListPreparedDataBuilderFactory.make()
        let restrictedOrganizationIds: [String] = await prepareRestrictedOrganizationIds(builder: preparedDataBuilder)

        await ciphersClientWrapperService.decryptAndProcessCiphersInBatch(
            ciphers: ciphers
        ) { decryptedCipher in
            guard decryptedCipher.deletedDate == nil,
                  decryptedCipher.passesRestrictItemTypesPolicy(restrictedOrganizationIds) else {
                return
            }

            let matchResult = cipherMatchingHelper.doesCipherMatch(cipher: decryptedCipher)

            preparedDataBuilder = await preparedDataBuilder.addItem(
                withMatchResult: matchResult,
                cipher: decryptedCipher
            )
        }

        return preparedDataBuilder.build()
    }

    // MARK: Private

    /// Returns the restricted organization IDs for the `.restrictItemTypes` policy if enabled
    /// and adds them to the builder.
    /// - Returns: The restricted organization IDs.
    func prepareRestrictedOrganizationIds(builder: VaultListPreparedDataBuilder) async -> [String] {
        guard await configService.getFeatureFlag(.removeCardPolicy) else {
            return []
        }
        let restrictedOrganizationIds = await policyService.getOrganizationIdsForRestricItemTypesPolicy()
        builder.prepareRestrictItemsPolicyOrganizations(restrictedOrganizationIds: restrictedOrganizationIds)
        return restrictedOrganizationIds
    }
}
