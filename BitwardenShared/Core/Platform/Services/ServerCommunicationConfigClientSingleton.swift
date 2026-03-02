import BitwardenKit
import BitwardenSdk

/// A lazily-initialized, cached holder for a `ServerCommunicationConfigClientProtocol` instance.
///
/// This protocol exists specifically to break a circular dependency in `ServiceContainer`:
///
/// 1. `APIService` (which also conforms to `ConfigAPIService`) needs a
///    `ServerCommunicationConfigClientSingleton` to power its SSO-cookie-vendor request and
///    response handlers.
/// 2. `DefaultServerCommunicationConfigClientSingleton` needs both `ClientService` (to create
///    the underlying SDK client) and `ConfigService` (to observe server-config changes and
///    push communication-type updates into the SDK).
/// 3. `DefaultClientService` depends on `ConfigService`.
/// 4. `DefaultConfigService` depends on `APIService` as its `ConfigAPIService`.
///
/// The result is the cycle: `APIService → ServerCommunicationConfigClientSingleton → ClientService
/// / ConfigService → APIService`.
///
/// The cycle is broken by injecting the singleton into `APIService` as a lazy closure
/// `() -> ServerCommunicationConfigClientSingleton?`.
protocol ServerCommunicationConfigClientSingleton {
    /// Returns the shared `ServerCommunicationConfigClientProtocol`, creating it on the first call.
    ///
    /// The underlying client is instantiated once and cached for the lifetime of the singleton.
    /// Subsequent calls return the same instance without re-creating it.
    ///
    /// - Throws: Any error thrown by `ClientService` while obtaining the pre-auth platform client
    ///   or by the SDK when initializing the server-communication-config client.
    /// - Returns: The shared `ServerCommunicationConfigClientProtocol` used to configure and
    ///   interact with the server-communication settings in the SDK.
    func client() async throws -> ServerCommunicationConfigClientProtocol

    /// Resolves the storage key for a given `hostname` by performing domain-suffix fallback.
    ///
    /// Tries the exact hostname first, then progressively strips the leftmost DNS label
    /// until a stored cookie configuration is found or no labels remain. This supports
    /// the case where cookies are stored under a parent domain (e.g., "bitwarden.com")
    /// but looked up by a subdomain (e.g., "api.bitwarden.com").
    ///
    /// - Parameter hostname: The exact hostname to check first.
    /// - Returns: The hostname key under which the config was saved.
    func resolveHostname(hostname: String) async -> String
}

/// Default implementation of `ServerCommunicationConfigClientSingleton`.
actor DefaultServerCommunicationConfigClientSingleton: ServerCommunicationConfigClientSingleton {
    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service to get server-specified configuration.
    private let configService: ConfigService

    /// The service used by the application to manage the environment settings.
    private let environmentService: EnvironmentService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The factory to create SDK repositories.
    private let sdkRepositoryFactory: SdkRepositoryFactory

    /// The service that bridges server communication configuration requests from the SDK.
    private let serverCommunicationConfigAPIService: ServerCommunicationConfigAPIService

    /// The server communication configuration client.
    private var serverCommunicationConfigClient: ServerCommunicationConfigClientProtocol?

    /// The service that provides state management functionality for the
    /// server communication configuration.
    private let serverCommunicationConfigStateService: ServerCommunicationConfigStateService

    /// Initializes a `DefaultServerCommunicationConfigClientSingleton`.
    /// - Parameters:
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - configService: The service to get server-specified configuration.
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - sdkRepositoryFactory: The factory to create SDK repositories.
    ///   - serverCommunicationConfigAPIService: The service that bridges server communication
    ///   configuration requests from the SDK.
    ///   - serverCommunicationConfigStateService: The service that provides state management functionality for the
    ///   server communication configuration.
    init(
        clientService: ClientService,
        configService: ConfigService,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        sdkRepositoryFactory: SdkRepositoryFactory,
        serverCommunicationConfigAPIService: ServerCommunicationConfigAPIService,
        serverCommunicationConfigStateService: ServerCommunicationConfigStateService,
    ) {
        self.clientService = clientService
        self.configService = configService
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.sdkRepositoryFactory = sdkRepositoryFactory
        self.serverCommunicationConfigAPIService = serverCommunicationConfigAPIService
        self.serverCommunicationConfigStateService = serverCommunicationConfigStateService

        Task {
            for await result in await configService.configPublisher() {
                guard let serverConfig = result?.serverConfig else {
                    continue
                }

                await updateSDKCommunicationType(serverConfig)
            }
        }
    }

    func client() async throws -> ServerCommunicationConfigClientProtocol {
        if let serverCommunicationConfigClient {
            return serverCommunicationConfigClient
        }

        // This server communication client can be created using any SDK client
        // as it depends on the objects we're passing.
        let serverConfigClient = try await clientService.platform(isPreAuth: true).serverCommunicationConfig(
            repository: sdkRepositoryFactory.makeServerCommunicationConfigRepository(),
            platformApi: serverCommunicationConfigAPIService,
        )
        serverCommunicationConfigClient = serverConfigClient
        return serverConfigClient
    }

    func resolveHostname(hostname: String) async -> String {
        do {
            guard let resolvedHostname = try await findServerCommunicationConfigHostname(hostname: hostname) else {
                return hostname
            }

            return resolvedHostname
        } catch {
            errorReporter.log(error: error)
            return hostname
        }
    }

    // MARK: Private Methods

    /// Finds the storage key of server communication config for a given `hostname`
    /// by performing domain-suffix fallback.
    ///
    /// Tries the exact hostname first, then progressively strips the leftmost DNS label
    /// until a stored cookie configuration is found or no labels remain. This supports
    /// the case where cookies are stored under a parent domain (e.g., "bitwarden.com")
    /// but looked up by a subdomain (e.g., "api.bitwarden.com").
    ///
    /// - Parameter hostname: The exact hostname to check first.
    /// - Returns: The hostname key under which the config was saved.
    private func findServerCommunicationConfigHostname(hostname: String) async throws -> String? {
        if try await serverCommunicationConfigStateService.getServerCommunicationConfig(hostname: hostname) != nil {
            return hostname
        }

        guard let firstDot = hostname.firstIndex(of: ".") else {
            return nil
        }

        let newHostname = String(hostname[hostname.index(after: firstDot)...])
        return try await findServerCommunicationConfigHostname(hostname: newHostname)
    }

    /// Updates the SDK communication type with the config gotten from the server.
    /// - Parameter config: The configuration for the update.
    private func updateSDKCommunicationType(_ config: ServerConfig) async {
        guard let communicationSettings = config.communication,
              let hostname = communicationSettings.bootstrap.cookieDomain ?? environmentService.webVaultURL.host else {
            return
        }

        do {
            var commSettings = ServerCommunicationConfig(communicationSettings: communicationSettings)
            let localConfig = try await serverCommunicationConfigStateService.getServerCommunicationConfig(
                hostname: hostname,
            )
            if let localConfig,
               case .ssoCookieVendor = commSettings.bootstrap,
               case .ssoCookieVendor = localConfig.bootstrap {
                commSettings = commSettings.updateCookieValue(from: localConfig)
            }

            try await client().setCommunicationType(
                hostname: hostname,
                config: commSettings,
            )
        } catch {
            errorReporter.log(error: error)
        }
    }
}
