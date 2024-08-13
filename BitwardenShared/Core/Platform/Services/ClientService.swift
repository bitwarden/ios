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
    func auth(for userId: String?) async throws -> ClientAuthProtocol

    /// Returns a `ClientCryptoProtocol` for crypto data tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `ClientCryptoProtocol` for crypto data tasks.
    ///
    func crypto(for userId: String?) async throws -> ClientCryptoProtocol

    /// Returns a `ClientExportersProtocol` for vault export data tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `ClientExportersProtocol` for vault export data tasks.
    ///
    func exporters(for userId: String?) async throws -> ClientExportersProtocol

    /// Returns a `ClientGeneratorsProtocol` for generator data tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `ClientGeneratorsProtocol` for generator data tasks.
    ///
    func generators(for userId: String?) async throws -> ClientGeneratorsProtocol

    /// Returns a `ClientPlatformService` for client platform tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `ClientPlatformService` for client platform tasks.
    ///
    func platform(for userId: String?) async throws -> ClientPlatformService

    /// Removes the user's client from memory.
    ///
    /// - Parameter userId: The user's ID.
    ///
    func removeClient(for userId: String?) async throws

    /// Returns a `ClientSendsProtocol` for send data tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `ClientSendsProtocol` for vault data tasks.
    ///
    func sends(for userId: String?) async throws -> ClientSendsProtocol

    /// Returns a `ClientVaultService` for vault data tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `ClientVaultService` for vault data tasks.
    ///
    func vault(for userId: String?) async throws -> ClientVaultService
}

// MARK: Extension

extension ClientService {
    /// Returns a `ClientAuthProtocol` for auth data tasks.
    ///
    func auth() async throws -> ClientAuthProtocol {
        try await auth(for: nil)
    }

    /// Returns a `ClientCryptoProtocol` for crypto data tasks.
    ///
    func crypto() async throws -> ClientCryptoProtocol {
        try await crypto(for: nil)
    }

    /// Returns a `ClientExportersProtocol` for vault export data tasks.
    ///
    func exporters() async throws -> ClientExportersProtocol {
        try await exporters(for: nil)
    }

    /// Returns a `ClientGeneratorsProtocol` for generator data tasks.
    ///
    func generators() async throws -> ClientGeneratorsProtocol {
        try await generators(for: nil)
    }

    /// Returns a `ClientPlatformService` for client platform tasks.
    ///
    func platform() async throws -> ClientPlatformService {
        try await platform(for: nil)
    }

    /// Removes the active user's client from memory.
    ///
    func removeClient() async throws {
        try await removeClient(for: nil)
    }

    /// Returns a `ClientSendsProtocol` for send data tasks.
    ///
    func sends() async throws -> ClientSendsProtocol {
        try await sends(for: nil)
    }

    /// Returns a `ClientVaultService` for vault data tasks.
    ///
    func vault() async throws -> ClientVaultService {
        try await vault(for: nil)
    }
}

// MARK: - DefaultClientService

/// A default `ClientService` implementation. This is a thin wrapper around the SDK `Client` so that
/// it can be swapped to a mock instance during tests.
///
class DefaultClientService: ClientService {
    // MARK: Private properties

    /// A helper object that builds a Bitwarden SDK `Client`.
    private let clientBuilder: ClientBuilder

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// Basic client behavior settings.
    private let settings: ClientSettings?

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// An array of user IDs and their associated client.
    private var userClientArray = [String: BitwardenSdkClient]()

    // MARK: Initialization

    /// Initialize a `DefaultClientService`.
    ///
    /// - Parameters:
    ///   - clientBuilder: A helper object that builds a Bitwarden SDK `Client`.
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
    }

    // MARK: Methods

    func auth(for userId: String?) async throws -> ClientAuthProtocol {
        try await client(for: userId).auth()
    }

    func crypto(for userId: String?) async throws -> ClientCryptoProtocol {
        try await client(for: userId).crypto()
    }

    func exporters(for userId: String?) async throws -> ClientExportersProtocol {
        try await client(for: userId).exporters()
    }

    func generators(for userId: String?) async throws -> ClientGeneratorsProtocol {
        try await client(for: userId).generators()
    }

    func platform(for userId: String?) async throws -> ClientPlatformService {
        try await client(for: userId).platform()
    }

    func removeClient(for userId: String?) async throws {
        let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
        userClientArray.removeValue(forKey: userId)
    }

    func sends(for userId: String?) async throws -> ClientSendsProtocol {
        try await client(for: userId).sends()
    }

    func vault(for userId: String?) async throws -> ClientVaultService {
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
            guard let client = userClientArray[userId] else {
                // If not, create one, map it to the user, then return it.
                let newClient = createAndMapClient(for: userId)
                return newClient
            }
            return client
        } catch StateServiceError.noAccounts, StateServiceError.noActiveAccount {
            // If there is no active account, or if no accounts exist,
            // return the original client.
            return clientBuilder.buildClient()
        }
    }

    /// Creates a new client and maps it to an ID.
    ///
    /// - Parameter userId: A user ID that the new client is being mapped to.
    ///
    private func createAndMapClient(for userId: String) -> BitwardenSdkClient {
        let client = clientBuilder.buildClient()

        userClientArray.updateValue(client, forKey: userId)
        return client
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

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The settings applied to the client.
    private let settings: ClientSettings?

    // MARK: Initialization

    /// Initializes a new client.
    ///
    /// - Parameters:
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - settings: The settings applied to the client.
    ///
    init(errorReporter: ErrorReporter, settings: ClientSettings? = nil) {
        self.errorReporter = errorReporter
        self.settings = settings
    }

    // MARK: Methods

    func buildClient() -> BitwardenSdkClient {
        let client = Client(settings: settings)

        return client
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
    func platform() -> ClientPlatformService

    /// Returns sends operations.
    func sends() -> ClientSendsProtocol

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

    func platform() -> ClientPlatformService {
        platform() as ClientPlatform
    }

    func sends() -> ClientSendsProtocol {
        sends() as ClientSends
    }

    func vault() -> ClientVaultService {
        vault() as ClientVault
    }
}
