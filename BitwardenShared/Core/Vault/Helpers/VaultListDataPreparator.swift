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
}

/// Default implementation of `VaultListDataPreparator`.
struct DefaultVaultListDataPreparator: VaultListDataPreparator {
    // MARK: Properties

    /// The wrapper of the `CiphersClient` service for extended functionality.
    let ciphersClientWrapperService: CiphersClientWrapperService
    /// The service used by the application to handle encryption and decryption tasks.
    let clientService: ClientService
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

        preparedDataBuilder = preparedDataBuilder
            .prepareFolders(folders: folders, filterType: filter.filterType)
            .prepareCollections(collections: collections, filterType: filter.filterType)

        await ciphersClientWrapperService.decryptAndProcessCiphersInBatch(
            ciphers: ciphers
        ) { decryptedCipher in
            guard filter.filterType.cipherFilter(decryptedCipher),
                  await policyService.passesRestrictItemTypesPolicy(cipher: decryptedCipher) else {
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

        preparedDataBuilder = preparedDataBuilder
            .prepareFolders(folders: folders, filterType: filter.filterType)
            .prepareCollections(collections: collections, filterType: filter.filterType)

        await ciphersClientWrapperService.decryptAndProcessCiphersInBatch(
            ciphers: ciphers
        ) { decryptedCipher in
            guard filter.filterType.cipherFilter(decryptedCipher),
                  await policyService.passesRestrictItemTypesPolicy(cipher: decryptedCipher) else {
                return
            }

            if case .folder = filter.group {
                preparedDataBuilder = preparedDataBuilder.addFolderItem(
                    cipher: decryptedCipher,
                    filter: filter,
                    folders: folders
                )
            }

            if case .collection = filter.group {
                preparedDataBuilder = preparedDataBuilder.incrementCollectionCount(cipher: decryptedCipher)
            }

            preparedDataBuilder = await preparedDataBuilder.addItem(forGroup: group, with: decryptedCipher)
        }

        return preparedDataBuilder.build()
    }
}
