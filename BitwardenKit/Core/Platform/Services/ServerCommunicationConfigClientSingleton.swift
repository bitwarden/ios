import BitwardenSdk

// MARK: - ServerCommunicationConfigClientSingleton

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
public protocol ServerCommunicationConfigClientSingleton {
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
