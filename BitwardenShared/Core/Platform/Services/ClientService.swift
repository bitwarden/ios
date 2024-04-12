import BitwardenSdk

/// A protocol for the service that handles common client functionality such as encryption and
/// decryption.
///
protocol ClientService {
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

    /// Whether or not the client is locked.
    ///
    /// - Parameter userId: The user's ID.
    /// - Returns: Whether or not the client is locked.
    ///
    func isLocked(userId: String) -> Bool

    /// Removes the client from the dictionary.
    ///
    /// - Parameter userId: The user's ID.
    ///
    func removeClient(userId: String)

    /// Updates the locked status of the user's client.
    ///
    /// - Parameters:
    ///   - userId: The user's ID.
    ///   - isLocked: Whether or not to lock the client.
    ///
    func updateClientLockedStatus(userId: String, isLocked: Bool)
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

    var userClientDictionary = [String: (client: BitwardenSdkClient, isLocked: Bool)]()

    // MARK: Private properties

    private let clientBuilder: ClientBuilder

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
        clientBuilder: ClientBuilder,
        errorReporter: ErrorReporter,
        settings: ClientSettings? = nil,
        stateService: StateService
    ) {
        self.clientBuilder = clientBuilder
        self.errorReporter = errorReporter
        self.settings = settings
        self.stateService = stateService

        Task {
            await loadFlags(client: clientBuilder.buildClient())
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
    private func client(for userId: String?) async throws -> BitwardenSdkClient {
        do {
            let userId = try await stateService.getAccountIdOrActiveId(userId: userId)

            // If the user has a client, return it.
            guard let client = userClientDictionary[userId] else {
                // If not, create one, map it to the user, then return it.
                let newClient = await createAndMapClient(for: userId)
                return newClient
            }
            return client.client
        } catch StateServiceError.noAccounts, StateServiceError.noActiveAccount {
            // If there is no active account, or if no accounts exist,
            // return the original client.
            return clientBuilder.buildClient()
        }
    }

    /// Creates a new client and maps it to a ID.
    ///
    /// - Parameter userId: A user ID that the new client is being mapped to.
    ///
    private func createAndMapClient(for userId: String) async -> BitwardenSdkClient {
        let client = clientBuilder.buildClient()

        // Load feature flags for the new client.
        await loadFlags(client: client)

        userClientDictionary.updateValue((client, true), forKey: userId)
        return client
    }

    /// Loads feature flags for a client instance.
    ///
    /// - Parameter client: The client that feature flags are applied to.
    ///
    private func loadFlags(client: BitwardenSdkClient) async {
        do {
            try await client.platform().loadFlags(
                flags: [FeatureFlagsConstants.enableCipherKeyEncryption: true]
            )
        } catch {
            errorReporter.log(error: error)
        }
    }

    func isLocked(userId: String) -> Bool {
        guard let client = userClientDictionary[userId] else {
            return true
        }
        return client.isLocked
    }

    func removeClient(userId: String) {
        userClientDictionary.removeValue(forKey: userId)
    }

    func updateClientLockedStatus(userId: String, isLocked: Bool) {
        guard let client = userClientDictionary[userId] else { return }
        userClientDictionary.updateValue((client.client, isLocked), forKey: userId)
    }
}

// MARK: - ClientBuilder

/// A protocol for creating a new `BitwardenSdkClient`.
///
protocol ClientBuilder {
    /// Creates a `BitwardenSdkClient`.
    ///
    /// - Returns: A new `BitwardenSdkClient`.
    ///
    func buildClient() -> BitwardenSdkClient
}

// MARK: DefaultClientBuilder

/// A default `ClientBuilder` implementation.
///
class DefaultClientBuilder: ClientBuilder {
    // MARK: Properties

    /// The client that will be returned.
    private let client: Client

    // MARK: Initialization

    /// Initializes a new client.
    ///
    /// - Parameter settings: The settings applied to the client.
    ///
    init(settings: ClientSettings? = nil) {
        client = Client(settings: settings)
    }

    // MARK: Methods

    func buildClient() -> BitwardenSdkClient {
        client
    }
}

// MARK: - BitwardenSdkClient

/// A protocol that exposed the SDK `ClientProtocol` methods.
///
protocol BitwardenSdkClient {
    /// Returns auth operations.
    func auth() -> ClientAuthProtocol

    /// Returns crypto operations.
    func crypto() -> ClientCryptoProtocol

    ///  Returns exporters.
    func exporters() -> ClientExportersProtocol

    /// Returns generator operations.
    func generators() -> ClientGeneratorsProtocol

    /// Returns platform operations.
    func platform() -> ClientPlatformProtocol

    /// Returns vault operations.
    func vault() -> ClientVaultService
}

// MARK: BitwardenSdkClient Extension

extension Client: BitwardenSdkClient {
    func auth() -> ClientAuthProtocol {
        auth() as ClientAuth
    }

    func crypto() -> ClientCryptoProtocol {
        crypto() as ClientCrypto
    }

    func exporters() -> ClientExportersProtocol {
        exporters() as ClientExporters
    }

    func generators() -> ClientGeneratorsProtocol {
        generators() as ClientGenerators
    }

    func platform() -> ClientPlatformProtocol {
        platform() as ClientPlatform
    }

    func vault() -> ClientVaultService {
        vault() as ClientVault
    }
}
