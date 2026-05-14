import BitwardenKit
import Networking
import UIKit

/// A service used by the application to make API requests.
///
class APIService {
    // MARK: Properties

    /// The API service that is used for general requests.
    let apiService: HTTPService

    /// The API service that is used for general unauthenticated requests.
    let apiUnauthenticatedService: HTTPService

    /// The API service used for logging events.
    let eventsService: HTTPService

    /// The API service used for HIBP requests.
    let hibpService: HTTPService

    /// The API service used for user identity requests.
    let identityService: HTTPService

    /// The service used by the application to manage account state
    let stateService: StateService

    // MARK: Private Properties

    /// A `TokenProvider` that gets the access token for the current account and can refresh it when
    /// necessary.
    let accountTokenProvider: AccountTokenProvider

    /// A builder for building an `HTTPService`.
    private let httpServiceBuilder: HTTPServiceBuilder

    // MARK: Initialization

    /// Initialize an `APIService` used to make API requests.
    ///
    /// - Parameters:
    ///   - accountTokenProvider: The `AccountTokenProvider` to use. This is helpful for testing.
    ///   The default will be built by default.
    ///   - activeAccountStateProvider: The provider for the active account state.
    ///   - client: The underlying `HTTPClient` that performs the network request. Defaults
    ///     to `URLSession.shared`.
    ///   - environmentService: The service used by the application to retrieve the environment settings.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - flightRecorder: The service used by the application for recording temporary debug logs.
    ///   - serverCommunicationConfigClientSingleton: The service to get the server communication client
    ///   used to break circular dependency.
    ///   - stateService: The service used by the application to manage account state.
    ///   - tokenService: The `TokenService` which manages accessing and updating the active
    ///     account's tokens.
    ///   - userAgentBuilder: Builds the user agent string from app and device information.
    ///
    init(
        accountTokenProvider: AccountTokenProvider? = nil,
        activeAccountStateProvider: ActiveAccountStateProvider,
        client: HTTPClient = URLSession.shared,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        flightRecorder: FlightRecorder,
        serverCommunicationConfigClientSingleton: @escaping () -> ServerCommunicationConfigClientSingleton?,
        stateService: StateService,
        tokenService: TokenService,
        userAgentBuilder: UserAgentBuilder,
    ) {
        self.stateService = stateService

        httpServiceBuilder = HTTPServiceBuilder(
            client: client,
            defaultHeadersRequestHandler: DefaultHeadersRequestHandler(
                appVersion: Bundle.main.appVersion,
                userAgentBuilder: userAgentBuilder,
            ),
            loggers: [
                FlightRecorderHTTPLogger(flightRecorder: flightRecorder),
                OSLogHTTPLogger(),
            ],
            ssoCookieVendorRequestHandler: SSOCookieVendorRequestHandler(
                serverCommunicationConfigClientSingleton: serverCommunicationConfigClientSingleton,
            ),
            ssoCookieVendorResponseHandler: SSOCookieVendorResponseHandler(
                serverCommunicationConfigClientSingleton: serverCommunicationConfigClientSingleton,
            ),
        )

        self.accountTokenProvider = accountTokenProvider ?? DefaultAccountTokenProvider(
            activeAccountStateProvider: activeAccountStateProvider,
            errorReporter: errorReporter,
            httpService: httpServiceBuilder.makeService(baseURLGetter: { environmentService.identityURL }),
            tokenService: tokenService,
        )

        apiService = httpServiceBuilder.makeService(
            baseURLGetter: { environmentService.apiURL },
            tokenProvider: self.accountTokenProvider,
        )
        apiUnauthenticatedService = httpServiceBuilder.makeService(
            baseURLGetter: { environmentService.apiURL },
        )
        eventsService = httpServiceBuilder.makeService(
            baseURLGetter: { environmentService.eventsURL },
            tokenProvider: self.accountTokenProvider,
        )
        hibpService = httpServiceBuilder.makeService(
            baseURLGetter: { URL(string: "https://api.pwnedpasswords.com")! },
        )
        identityService = httpServiceBuilder.makeService(
            baseURLGetter: { environmentService.identityURL },
        )
    }

    // MARK: Methods

    /// Builds a `HTTPService` to communicate with the key connector API.
    ///
    /// - Parameter baseURL: The base URL to use for key connector API requests.
    /// - Returns: A `HTTPService` to communicate with the key connector API.
    ///
    func buildKeyConnectorService(baseURL: URL) -> HTTPService {
        httpServiceBuilder.makeService(
            baseURLGetter: { baseURL },
            tokenProvider: accountTokenProvider,
        )
    }

    /// Sets the account token provider delegate.
    /// - Parameter delegate: The delegate to use.
    func setAccountTokenProviderDelegate(delegate: AccountTokenProviderDelegate) async {
        await accountTokenProvider.setDelegate(delegate: delegate)
    }
}
