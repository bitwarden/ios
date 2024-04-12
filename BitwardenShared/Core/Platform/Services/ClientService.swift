import BitwardenSdk

/// A protocol for service that handles common client functionality such as encryption and
/// decryption.
///
protocol ClientService {
    // MARK: Properties

    /// A dictionary mapping a user ID to a client and the client's lock status.
    var userClientDictionary: [String: (client: Client, isLocked: Bool)] { get set }

    // MARK: Methods

    /// Returns a `ClientAuthProtocol` for auth data tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `ClientAuthProtocol` for auth data tasks.
    ///
    func clientAuth(for userId: String?) async throws -> ClientAuthProtocol

    /// Returns a `ClientCryptoProtocol` for crypto data tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `ClientCryptoProtocol` for crypto data tasks.
    ///
    func clientCrypto(for userId: String?) async throws -> ClientCryptoProtocol

    /// Returns a `ClientExportersProtocol` for vault export data tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `ClientExportersProtocol` for vault export data tasks.
    ///
    func clientExporters(for userId: String?) async throws -> ClientExportersProtocol

    /// Returns a `ClientGeneratorsProtocol` for generator data tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `ClientGeneratorsProtocol` for generator data tasks.
    ///
    func clientGenerator(for userId: String?) async throws -> ClientGeneratorsProtocol

    /// Returns a `ClientPlatformProtocol` for client platform tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `ClientPlatformProtocol` for client platform tasks.
    ///
    func clientPlatform(for userId: String?) async throws -> ClientPlatformProtocol

    /// Returns a `ClientVaultService` for vault data tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `ClientVaultService` for vault data tasks.
    ///
    func clientVault(for userId: String?) async throws -> ClientVaultService
}

// MARK: Extension

extension ClientService {
    /// Returns a `ClientAuthProtocol` for auth data tasks.
    ///
    func clientAuth() async throws -> ClientAuthProtocol {
        try await clientAuth(for: nil)
    }

    /// Returns a `ClientCryptoProtocol` for crypto data tasks.
    ///
    func clientCrypto() async throws -> ClientCryptoProtocol {
        try await clientCrypto(for: nil)
    }

    /// Returns a `ClientExportersProtocol` for vault export data tasks.
    ///
    func clientExporters() async throws -> ClientExportersProtocol {
        try await clientExporters(for: nil)
    }

    /// Returns a `ClientGeneratorsProtocol` for generator data tasks.
    ///
    func clientGenerator() async throws -> ClientGeneratorsProtocol {
        try await clientGenerator(for: nil)
    }

    /// Returns a `ClientPlatformProtocol` for client platform tasks.
    ///
    func clientPlatform() async throws -> ClientPlatformProtocol {
        try await clientPlatform(for: nil)
    }

    /// Returns a `ClientVaultService` for vault data tasks.
    ///
    func clientVault() async throws -> ClientVaultService {
        try await clientVault(for: nil)
    }
}

// MARK: - DefaultClientService

/// A default `ClientService` implementation. This is a thin wrapper around the SDK `Client` so that
/// it can be swapped to a mock instance during tests.
///
class DefaultClientService: ClientService {
    // MARK: Properties

    var userClientDictionary = [String: (client: Client, isLocked: Bool)]()

    // MARK: Private properties

    /// The `Client` instance used to access `BitwardenSdk`.
    private let client: Client

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// Basic client behavior settings.
    private let settings: ClientSettings?

    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultClientService`.
    ///
    /// - Parameters:
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - settings: The settings to apply to the client. Defaults to `nil`.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        errorReporter: ErrorReporter,
        settings: ClientSettings? = nil,
        stateService: StateService
    ) {
        self.errorReporter = errorReporter
        self.settings = settings
        self.stateService = stateService

        client = Client(settings: settings)

        Task {
            await loadFlags(client: client)
        }
    }

    // MARK: Methods

    func clientAuth(for userId: String?) async throws -> ClientAuthProtocol {
        try await client(for: userId).auth()
    }

    func clientCrypto(for userId: String?) async throws -> ClientCryptoProtocol {
        try await client(for: userId).crypto()
    }

    func clientExporters(for userId: String?) async throws -> ClientExportersProtocol {
        try await client(for: userId).exporters()
    }

    func clientGenerator(for userId: String?) async throws -> ClientGeneratorsProtocol {
        try await client(for: userId).generators()
    }

    func clientPlatform(for userId: String?) async throws -> ClientPlatformProtocol {
        try await client(for: userId).platform()
    }

    func clientVault(for userId: String?) async throws -> ClientVaultService {
        try await client(for: userId).vault()
    }

    // MARK: Private methods

    /// Returns a user's client if it exists. If the user has no client, create one and map it to their user ID.
    ///
    ///
    /// If there is no active user/there are no accounts, return the original client.
    /// This could occur if the app is launched from a fresh install.
    ///
    /// - Parameter userId: A user ID for which a `Client` is mapped to or will be mapped to.
    /// - Returns: A user's client.
    ///
    private func client(for userId: String?) async throws -> Client {
        do {
            let userId = try await stateService.getAccountIdOrActiveId(userId: userId)

            // If the user has a client, return it.
            for _ in userClientDictionary {
                if let client = userClientDictionary[userId] {
                    return client.client
                }
            }

            // If not, create one, map it to the user, then return it.
            let newClient = await createAndMapClient(for: userId)
            return newClient
        } catch StateServiceError.noAccounts, StateServiceError.noActiveAccount {
            // If there is no active account, or if no accounts exist,
            // return the original client.
            return client
        }
    }

    /// Creates a new client and maps it to a ID.
    ///
    /// - Parameter userId: A user ID that the new client is being mapped to.
    ///
    private func createAndMapClient(for userId: String) async -> Client {
        let client = Client(settings: settings)

        // Load feature flags for the new client.
        await loadFlags(client: client)

        userClientDictionary.updateValue((client, true), forKey: userId)
        return client
    }

    /// Loads feature flags for a client instance.
    ///
    /// - Parameter client: The client that feature flags are applied to.
    ///
    private func loadFlags(client: Client) async {
        do {
            try await client.platform().loadFlags(
                flags: [FeatureFlagsConstants.enableCipherKeyEncryption: true]
            )
        } catch {
            errorReporter.log(error: error)
        }
    }
}
