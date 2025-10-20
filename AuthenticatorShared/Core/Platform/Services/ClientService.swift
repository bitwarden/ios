import BitwardenKit
import BitwardenSdk

/// A protocol for the service that handles common client functionality such as encryption and
/// decryption.
///
protocol ClientService {
    // MARK: Methods

    /// Returns a `AuthClientProtocol` for auth data tasks.
    ///
    /// - Parameters:
    ///   - userId: The user ID mapped to the client instance.
    ///   - isPreAuth: Whether the client is being used for a user prior to authentication (when
    ///     the user's ID doesn't yet exist).
    /// - Returns: A `AuthClientProtocol` for auth data tasks.
    ///
    func auth(for userId: String?, isPreAuth: Bool) async throws -> AuthClientProtocol

    /// Returns a `CryptoClientProtocol` for crypto data tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `CryptoClientProtocol` for crypto data tasks.
    ///
    func crypto(for userId: String?) async throws -> CryptoClientProtocol

    /// Returns a `ExporterClientProtocol` for vault export data tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `ExporterClientProtocol` for vault export data tasks.
    ///
    func exporters(for userId: String?) async throws -> ExporterClientProtocol

    /// Returns a `GeneratorClientsProtocol` for generator data tasks.
    ///
    /// - Parameters:
    ///   - userId: The user ID mapped to the client instance.
    ///   - isPreAuth: Whether the client is being used for a user prior to authentication (when
    ///     the user's ID doesn't yet exist).
    /// - Returns: A `GeneratorClientsProtocol` for generator data tasks.
    ///
    func generators(for userId: String?, isPreAuth: Bool) async throws -> GeneratorClientsProtocol

    /// Returns a `PlatformClientService` for client platform tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `PlatformClientService` for client platform tasks.
    ///
    func platform(for userId: String?) async throws -> PlatformClientService

    /// Removes the user's client from memory.
    ///
    /// - Parameter userId: The user's ID.
    ///
    func removeClient(for userId: String?) async throws

    /// Returns a `SendClientProtocol` for send data tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `SendClientProtocol` for vault data tasks.
    ///
    func sends(for userId: String?) async throws -> SendClientProtocol

    /// Returns a `VaultClientService` for vault data tasks.
    ///
    /// - Parameter userId: The user ID mapped to the client instance.
    /// - Returns: A `VaultClientService` for vault data tasks.
    ///
    func vault(for userId: String?) async throws -> VaultClientService
}

// MARK: Extension

extension ClientService {
    /// Returns a `AuthClientProtocol` for auth data tasks.
    ///
    /// - Parameter isPreAuth: Whether the client is being used for a user prior to authentication
    ///     (when the user's ID doesn't yet exist).
    ///
    func auth(isPreAuth: Bool = false) async throws -> AuthClientProtocol {
        try await auth(for: nil, isPreAuth: isPreAuth)
    }

    /// Returns a `CryptoClientProtocol` for crypto data tasks.
    ///
    func crypto() async throws -> CryptoClientProtocol {
        try await crypto(for: nil)
    }

    /// Returns a `ExporterClientProtocol` for vault export data tasks.
    ///
    func exporters() async throws -> ExporterClientProtocol {
        try await exporters(for: nil)
    }

    /// Returns a `GeneratorClientsProtocol` for generator data tasks.
    ///
    /// - Parameter isPreAuth: Whether the client is being used for a user prior to authentication
    ///     (when the user's ID doesn't yet exist). This primarily will happen in SSO flows.
    ///
    func generators(isPreAuth: Bool = false) async throws -> GeneratorClientsProtocol {
        try await generators(for: nil, isPreAuth: isPreAuth)
    }

    /// Returns a `PlatformClientService` for client platform tasks.
    ///
    func platform() async throws -> PlatformClientService {
        try await platform(for: nil)
    }

    /// Removes the active user's client from memory.
    ///
    func removeClient() async throws {
        try await removeClient(for: nil)
    }

    /// Returns a `SendClientProtocol` for send data tasks.
    ///
    func sends() async throws -> SendClientProtocol {
        try await sends(for: nil)
    }

    /// Returns a `VaultClientService` for vault data tasks.
    ///
    func vault() async throws -> VaultClientService {
        try await vault(for: nil)
    }
}

// MARK: - DefaultClientService

/// A default `ClientService` implementation. This is a thin wrapper around the SDK `Client` so that
/// it can be swapped to a mock instance during tests.
///
actor DefaultClientService: ClientService {
    // MARK: Private properties

    /// A helper object that builds a Bitwarden SDK `Client`.
    private let clientBuilder: ClientBuilder

    /// The service to get server-specified configuration.
    private let configService: ConfigService

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
    ///   - configService: The service to get server-specified configuration.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - settings: The settings to apply to the client. Defaults to `nil`.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        clientBuilder: ClientBuilder,
        configService: ConfigService,
        errorReporter: ErrorReporter,
        settings: ClientSettings? = nil,
        stateService: StateService,
    ) {
        self.clientBuilder = clientBuilder
        self.configService = configService
        self.errorReporter = errorReporter
        self.settings = settings
        self.stateService = stateService
    }

    // MARK: Methods

    func auth(for userId: String?, isPreAuth: Bool = false) async throws -> AuthClientProtocol {
        try await client(for: userId, isPreAuth: isPreAuth).auth()
    }

    func crypto(for userId: String?) async throws -> CryptoClientProtocol {
        try await client(for: userId).crypto()
    }

    func exporters(for userId: String?) async throws -> ExporterClientProtocol {
        try await client(for: userId).exporters()
    }

    func generators(for userId: String?, isPreAuth: Bool = false) async throws -> GeneratorClientsProtocol {
        try await client(for: userId, isPreAuth: isPreAuth).generators()
    }

    func platform(for userId: String?) async throws -> PlatformClientService {
        try await client(for: userId).platform()
    }

    func removeClient(for userId: String?) async throws {}

    func sends(for userId: String?) async throws -> SendClientProtocol {
        try await client(for: userId).sends()
    }

    func vault(for userId: String?) async throws -> VaultClientService {
        try await client(for: userId).vault()
    }

    // MARK: Private methods

    /// Returns a user's client if it exists. If the user has no client, create one and map it to their user ID.
    ///
    ///
    /// If there is no active user/there are no accounts, return a new client.
    /// This could occur if the app is launched from a fresh install.
    ///
    /// - Parameters:
    ///   - userId: A user ID for which a `Client` is mapped to or will be mapped to.
    ///   - isPreAuth: Whether the client is being used for a user prior to authentication (when
    ///     the user's ID doesn't yet exist).
    /// - Returns: A user's client.
    ///
    private func client(for userId: String?, isPreAuth: Bool = false) async throws -> BitwardenSdkClient {
        clientBuilder.buildClient()
    }

    /// Creates a new client and maps it to an ID.
    ///
    /// - Parameter userId: A user ID that the new client is being mapped to.
    ///
    private func createAndMapClient(for userId: String) async -> BitwardenSdkClient {
        let client = clientBuilder.buildClient()

        userClientArray.updateValue(client, forKey: userId)
        return client
    }

    /// Loads the flags into the SDK.
    /// - Parameter config: Config to update the flags.
    private func loadFlags(_ config: ServerConfig?, for client: BitwardenSdkClient) async {}
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
        Client(tokenProvider: DefaultClientManagedTokensProvider(), settings: settings)
    }
}

// MARK: - BitwardenSdkClient

/// A protocol that exposed the SDK `ClientProtocol` methods.
///
protocol BitwardenSdkClient {
    /// Returns auth operations.
    func auth() -> AuthClientProtocol

    /// Returns crypto operations.
    func crypto() -> CryptoClientProtocol

    ///  Returns exporters.
    func exporters() -> ExporterClientProtocol

    /// Returns generator operations.
    func generators() -> GeneratorClientsProtocol

    /// Returns platform operations.
    func platform() -> PlatformClientService

    /// Returns sends operations.
    func sends() -> SendClientProtocol

    /// Returns vault operations.
    func vault() -> VaultClientService
}

// MARK: BitwardenSdkClient Extension

extension Client: BitwardenSdkClient {
    func auth() -> AuthClientProtocol {
        auth() as AuthClient
    }

    func crypto() -> CryptoClientProtocol {
        crypto() as CryptoClient
    }

    func exporters() -> ExporterClientProtocol {
        exporters() as ExporterClient
    }

    func generators() -> GeneratorClientsProtocol {
        generators() as GeneratorClients
    }

    func platform() -> PlatformClientService {
        platform() as PlatformClient
    }

    func sends() -> SendClientProtocol {
        sends() as SendClient
    }

    func vault() -> VaultClientService {
        vault() as VaultClient
    }
}

// MARK: DefaultTokenProvider

/// Default implementation of the SDK's `ClientManagedTokens`.
/// Given that we are not performing authenticated API calls in BWA
/// we just return `nil` for the access token.
final class DefaultClientManagedTokensProvider: ClientManagedTokens {
    func getAccessToken() async -> String? {
        nil
    }
}
