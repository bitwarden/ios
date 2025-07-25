import BitwardenKit
import BitwardenSdk

/// A factory to create SDK repositories.
protocol SdkRepositoryFactory { // sourcery: AutoMockable
    /// Makes a `BitwardenSdk.CipherRepository` for the given `userId`.
    /// - Parameter userId: The user ID to use in the repository which belongs to the SDK instance
    /// the repository will be registered in.
    /// - Returns: The repository for the given `userId`.
    func makeCipherRepository(userId: String) -> BitwardenSdk.CipherRepository
}

/// Default implementation of `SdkRepositoryFactory`.
struct DefaultSdkRepositoryFactory: SdkRepositoryFactory {
    // MARK: Properties

    /// The data store for managing the persisted ciphers for the user.
    private let cipherDataStore: CipherDataStore
    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    // MARK: Init

    /// Initializes a `DefaultSdkRepositoryFactory`.
    /// - Parameters:
    ///   - cipherDataStore: The data store for managing the persisted ciphers for the user.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    init(cipherDataStore: CipherDataStore, errorReporter: ErrorReporter) {
        self.cipherDataStore = cipherDataStore
        self.errorReporter = errorReporter
    }

    // MARK: Methods

    func makeCipherRepository(userId: String) -> BitwardenSdk.CipherRepository {
        SdkCipherRepository(
            cipherDataStore: cipherDataStore,
            errorReporter: errorReporter,
            userId: userId
        )
    }
}
