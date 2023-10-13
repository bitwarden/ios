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
    ///   - baseUrlService: The service to get base urls used for all requests in this service.
    ///   - client: The underlying `HTTPClient` that performs the network request. Defaults
    ///     to `URLSession.shared`.
    ///   - tokenService: The `TokenService` which manages accessing and updating the active
    ///     account's tokens.
    ///
    init(
        baseUrlService: BaseUrlService,
        client: HTTPClient = URLSession.shared,
        tokenService: TokenService
    ) {
        let defaultHeadersRequestHandler = DefaultHeadersRequestHandler(
            appName: Bundle.main.appName,
            appVersion: Bundle.main.appVersion,
            buildNumber: Bundle.main.buildNumber,
            systemDevice: UIDevice.current
        )

        let accountTokenProvider = AccountTokenProvider(
            httpService: HTTPService(
                baseUrlGetter: { baseUrlService.baseUrl.appendingPathComponent("/identity") },
                client: client,
                requestHandlers: [defaultHeadersRequestHandler]
            ),
            tokenService: tokenService
        )

        apiService = HTTPService(
            baseUrlGetter: { baseUrlService.baseUrl.appendingPathComponent("/api") },
            client: client,
            requestHandlers: [defaultHeadersRequestHandler],
            tokenProvider: accountTokenProvider
        )
        apiUnauthenticatedService = HTTPService(
            baseUrlGetter: { baseUrlService.baseUrl.appendingPathComponent("/api") },
            client: client,
            requestHandlers: [defaultHeadersRequestHandler]
        )
        eventsService = HTTPService(
            baseUrlGetter: { baseUrlService.baseUrl.appendingPathComponent("/events") },
            client: client,
            requestHandlers: [defaultHeadersRequestHandler]
        )
        hibpService = HTTPService(
            baseURL: URL(string: "https://api.pwnedpasswords.com")!,
            client: client,
            requestHandlers: [defaultHeadersRequestHandler]
        )
        identityService = HTTPService(
            baseUrlGetter: { baseUrlService.baseUrl.appendingPathComponent("/identity") },
            client: client,
            requestHandlers: [defaultHeadersRequestHandler]
        )
    }
}
