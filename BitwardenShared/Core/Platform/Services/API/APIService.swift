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

    // MARK: Private Properties

    /// A `TokenProvider` that gets the access token for the current account and can refresh it when
    /// necessary.
    private let accountTokenProvider: AccountTokenProvider

    /// The underlying `HTTPClient` that performs the network request.
    private let client: HTTPClient

    /// A `RequestHandler` that applies default headers (user agent, client type & name, etc) to requests.
    private let defaultHeadersRequestHandler: DefaultHeadersRequestHandler

    /// A `ResponseHandler` that validates that HTTP responses contain successful (2XX) HTTP status
    /// codes or tries to parse the error otherwise.
    private let responseValidationHandler = ResponseValidationHandler()

    // MARK: Initialization

    /// Initialize an `APIService` used to make API requests.
    ///
    /// - Parameters:
    ///   - client: The underlying `HTTPClient` that performs the network request. Defaults
    ///     to `URLSession.shared`.
    ///   - environmentService: The service used by the application to retrieve the environment settings.
    ///   - tokenService: The `TokenService` which manages accessing and updating the active
    ///     account's tokens.
    ///
    init(
        client: HTTPClient = URLSession.shared,
        environmentService: EnvironmentService,
        tokenService: TokenService
    ) {
        self.client = client

        defaultHeadersRequestHandler = DefaultHeadersRequestHandler(
            appName: "Bitwarden_Mobile",
            appVersion: Bundle.main.appVersion,
            buildNumber: Bundle.main.buildNumber,
            systemDevice: UIDevice.current
        )

        accountTokenProvider = AccountTokenProvider(
            httpService: HTTPService(
                baseUrlGetter: { environmentService.identityURL },
                client: client,
                requestHandlers: [defaultHeadersRequestHandler],
                responseHandlers: [responseValidationHandler]
            ),
            tokenService: tokenService
        )

        apiService = HTTPService(
            baseUrlGetter: { environmentService.apiURL },
            client: client,
            requestHandlers: [defaultHeadersRequestHandler],
            responseHandlers: [responseValidationHandler],
            tokenProvider: accountTokenProvider
        )
        apiUnauthenticatedService = HTTPService(
            baseUrlGetter: { environmentService.apiURL },
            client: client,
            requestHandlers: [defaultHeadersRequestHandler],
            responseHandlers: [responseValidationHandler]
        )
        eventsService = HTTPService(
            baseUrlGetter: { environmentService.eventsURL },
            client: client,
            requestHandlers: [defaultHeadersRequestHandler],
            responseHandlers: [responseValidationHandler],
            tokenProvider: accountTokenProvider
        )
        hibpService = HTTPService(
            baseURL: URL(string: "https://api.pwnedpasswords.com")!,
            client: client,
            requestHandlers: [defaultHeadersRequestHandler],
            responseHandlers: [responseValidationHandler]
        )
        identityService = HTTPService(
            baseUrlGetter: { environmentService.identityURL },
            client: client,
            requestHandlers: [defaultHeadersRequestHandler],
            responseHandlers: [responseValidationHandler]
        )
    }

    // MARK: Methods

    /// Builds a `HTTPService` to communicate with the key connector API.
    ///
    /// - Parameter baseURL: The base URL to use for key connector API requests.
    /// - Returns: A `HTTPService` to communicate with the key connector API.
    ///
    func buildKeyConnectorService(baseURL: URL) -> HTTPService {
        HTTPService(
            baseURL: baseURL,
            client: client,
            requestHandlers: [defaultHeadersRequestHandler],
            responseHandlers: [responseValidationHandler],
            tokenProvider: accountTokenProvider
        )
    }
}
