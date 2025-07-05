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

/// The default implemetnation of `VaultListSectionsBuilderFactory`.
struct DefaultVaultListSectionsBuilderFactory: VaultListSectionsBuilderFactory {
    /// The service used by the application to handle encryption and decryption tasks.
    let clientService: ClientService
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    func make(withData preparedData: VaultListPreparedData) -> VaultListSectionsBuilder {
        DefaultVaultListSectionsBuilder(
            clientService: clientService,
            errorReporter: errorReporter,
            withData: preparedData
        )
    }
}
