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
        let defaultHeadersRequestHandler = DefaultHeadersRequestHandler(
            appName: "Bitwarden_Mobile",
            appVersion: Bundle.main.appVersion,
            buildNumber: Bundle.main.buildNumber,
            systemDevice: UIDevice.current
        )
        let responseValidationHandler = ResponseValidationHandler()

        let accountTokenProvider = AccountTokenProvider(
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
            responseHandlers: [responseValidationHandler]
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
}
