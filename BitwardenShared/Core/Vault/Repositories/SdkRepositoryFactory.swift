import BitwardenKit
import BitwardenSdk

/// A factory to create SDK repositories.
protocol SdkRepositoryFactory { // sourcery: AutoMockable
    /// Makes a `BitwardenSdk.CipherRepository` for the given `userId`.
    /// - Parameter userId: The user ID to use in the repository which belongs to the SDK instance
    /// the repository will be registered in.
    /// - Returns: The repository for the given `userId`.
    func makeCipherRepository(userId: String) -> BitwardenSdk.CipherRepository

    /// Makes a `BitwardenSdk.ServerCommunicationConfigRepository`.
    /// - Returns: The repository to use for server communication config.
    func makeServerCommunicationConfigRepository() -> BitwardenSdk.ServerCommunicationConfigRepository
}

/// Default implementation of `SdkRepositoryFactory`.
struct DefaultSdkRepositoryFactory: SdkRepositoryFactory {
    // MARK: Properties

    /// The data store for managing the persisted ciphers for the user.
    private let cipherDataStore: CipherDataStore
    /// The service to get server-specified configuration.
    private let configService: ConfigService
    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter
    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: Init
    
    /// Initializes a `DefaultSdkRepositoryFactory`.
    /// - Parameters:
    ///   - cipherDataStore: The data store for managing the persisted ciphers for the user.
    ///   - configService: The service to get server-specified configuration.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The service used by the application to manage account state.
    init(
        cipherDataStore: CipherDataStore,
        configService: ConfigService,
        errorReporter: ErrorReporter,
        stateService: StateService,
    ) {
        self.cipherDataStore = cipherDataStore
        self.configService = configService
        self.errorReporter = errorReporter
        self.stateService = stateService
    }

    // MARK: Methods

    func makeCipherRepository(userId: String) -> BitwardenSdk.CipherRepository {
        SdkCipherRepository(
            cipherDataStore: cipherDataStore,
            errorReporter: errorReporter,
            userId: userId,
        )
    }

    func makeServerCommunicationConfigRepository() -> BitwardenSdk.ServerCommunicationConfigRepository {
        SdkServerCommunicationConfigRepository(configService: configService, stateService: stateService)
    }
}
