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

    func prepareAutofillPasswordsData(
        from ciphers: [Cipher],
        filter: VaultListFilter,
    ) async -> VaultListPreparedData? {
        guard !ciphers.isEmpty, let uri = filter.uri else {
            return nil
        }

        let cipherMatchingHelper = await cipherMatchingHelperFactory.make(uri: uri)

        var preparedDataBuilder = vaultListPreparedDataBuilderFactory.make()
        let restrictedOrganizationIds = await prepareRestrictedOrganizationIds(builder: preparedDataBuilder)

        await ciphersClientWrapperService.decryptAndProcessCiphersInBatch(
            ciphers: ciphers,
        ) { decryptedCipher in
            guard decryptedCipher.type.isLogin,
                  decryptedCipher.deletedDate == nil,
                  decryptedCipher.canBeUsedInBasicLoginAutofill,
                  decryptedCipher.passesRestrictItemTypesPolicy(restrictedOrganizationIds) else {
                return
            }

            let matchResult = cipherMatchingHelper.doesCipherMatch(cipher: decryptedCipher)

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
        let restrictedOrganizationIds = await prepareRestrictedOrganizationIds(builder: preparedDataBuilder)

        await ciphersClientWrapperService.decryptAndProcessCiphersInBatch(
            ciphers: ciphers,
        ) { decryptedCipher in
            guard decryptedCipher.type.isLogin,
                  decryptedCipher.deletedDate == nil,
                  decryptedCipher.passesRestrictItemTypesPolicy(restrictedOrganizationIds) else {
                return
            }

            let matchResult = cipherMatchingHelper.doesCipherMatch(cipher: decryptedCipher)
            guard matchResult != .none else {
                return
            }

            if let fido2Credentials,
               decryptedCipher.type.loginListView?.hasFido2 == true,
               fido2Credentials.contains(where: { $0.id == decryptedCipher.id }) {
                preparedDataBuilder = await preparedDataBuilder.addFido2Item(cipher: decryptedCipher)
            }

            if decryptedCipher.canBeUsedInBasicLoginAutofill {
                preparedDataBuilder = await preparedDataBuilder.addItem(
                    forGroup: .login,
                    with: decryptedCipher,
                )
            }
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
        let restrictedOrganizationIds = await prepareRestrictedOrganizationIds(builder: preparedDataBuilder)

        await ciphersClientWrapperService.decryptAndProcessCiphersInBatch(
            ciphers: ciphers,
        ) { decryptedCipher in
            guard decryptedCipher.type.isLogin,
                  decryptedCipher.deletedDate == nil,
                  decryptedCipher.passesRestrictItemTypesPolicy(restrictedOrganizationIds) else {
                return
            }

            let matchResult = cipherMatchingHelper.doesCipherMatch(cipher: decryptedCipher)
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
        let restrictedOrganizationIds = await prepareRestrictedOrganizationIds(builder: preparedDataBuilder)

        preparedDataBuilder = preparedDataBuilder
            .prepareFolders(folders: folders, filterType: filter.filterType)
            .prepareCollections(collections: collections, filterType: filter.filterType)

        await ciphersClientWrapperService.decryptAndProcessCiphersInBatch(
            ciphers: ciphers,
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
        filter: VaultListFilter,
    ) async -> VaultListPreparedData? {
        guard !ciphers.isEmpty, let group = filter.group else {
            return nil
        }

        var preparedDataBuilder = vaultListPreparedDataBuilderFactory.make()
        let restrictedOrganizationIds: [String] = await prepareRestrictedOrganizationIds(builder: preparedDataBuilder)

        preparedDataBuilder = preparedDataBuilder
            .prepareFolders(folders: folders, filterType: filter.filterType)
            .prepareCollections(collections: collections, filterType: filter.filterType)

        await ciphersClientWrapperService.decryptAndProcessCiphersInBatch(
            ciphers: ciphers,
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

    // MARK: Private

    /// Returns the restricted organization IDs for the `.restrictItemTypes` policy and adds them
    /// to the builder.
    /// - Returns: The restricted organization IDs.
    func prepareRestrictedOrganizationIds(builder: VaultListPreparedDataBuilder) async -> [String] {
        let restrictedOrganizationIds = await policyService.getOrganizationIdsForRestricItemTypesPolicy()
        builder.prepareRestrictItemsPolicyOrganizations(restrictedOrganizationIds: restrictedOrganizationIds)
        return restrictedOrganizationIds
    }
}
