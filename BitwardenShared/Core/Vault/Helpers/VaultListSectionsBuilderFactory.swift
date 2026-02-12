import BitwardenKit

// MARK: - VaultListSectionsBuilderFactory

/// A factory protocol to make vault list builders.
protocol VaultListSectionsBuilderFactory { // sourcery: AutoMockable
    /// Makes a `VaultListSectionsBuilder` with prepared data.
    /// - Parameter with: `VaultListPreparedData` to be used as input for the builder.
    /// Then the caller can decide which parts of the prepared data to include by calling each of the builder methods.
    /// - Returns: The builder for the vault list sections.
    func make(withData preparedData: VaultListPreparedData) -> VaultListSectionsBuilder
}

// MARK: - DefaultVaultListSectionsBuilderFactory

/// The default implementation of `VaultListSectionsBuilderFactory`.
struct DefaultVaultListSectionsBuilderFactory: VaultListSectionsBuilderFactory {
    /// The service used by the application to handle encryption and decryption tasks.
    let clientService: ClientService
    /// The helper functions for collections.
    let collectionHelper: CollectionHelper
    /// The service to get server-specified configuration.
    let configService: ConfigService
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter
    /// The service used by the application to manage account state.
    let stateService: StateService

    func make(withData preparedData: VaultListPreparedData) -> VaultListSectionsBuilder {
        DefaultVaultListSectionsBuilder(
            clientService: clientService,
            collectionHelper: collectionHelper,
            configService: configService,
            errorReporter: errorReporter,
            stateService: stateService,
            withData: preparedData,
        )
    }
}
