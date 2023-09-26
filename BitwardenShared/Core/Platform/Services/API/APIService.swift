import Networking
import UIKit

/// A service used by the application to make API requests.
///
class APIService {
    // MARK: Properties

    /// The API service that is used for general requests.
    let apiService: HTTPService

    /// The base url used for all requests in this service.
    let baseUrl: URL

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
    ///   - baseUrl: The base url used for all requests in this service.
    ///   - client: The underlying `HTTPClient` that performs the network request. Defaults
    ///     to `URLSession.shared`.
    ///
    init(
        baseUrl: URL,
        client: HTTPClient = URLSession.shared
    ) {
        self.baseUrl = baseUrl
        let defaultHeadersRequestHandler = DefaultHeadersRequestHandler(
            appName: Bundle.main.appName,
            appVersion: Bundle.main.appVersion,
            buildNumber: Bundle.main.buildNumber,
            systemDevice: UIDevice.current
        )

        apiService = HTTPService(
            baseURL: baseUrl.appendingPathComponent("/api"),
            client: client,
            requestHandlers: [defaultHeadersRequestHandler]
        )
        eventsService = HTTPService(
            baseURL: baseUrl.appendingPathComponent("/events"),
            client: client,
            requestHandlers: [defaultHeadersRequestHandler]
        )
        hibpService = HTTPService(
            baseURL: URL(string: "https://api.pwnedpasswords.com")!,
            client: client,
            requestHandlers: [defaultHeadersRequestHandler]
        )
        identityService = HTTPService(
            baseURL: baseURL: baseUrl.appendingPathComponent("/identity"),
            client: client,
            requestHandlers: [defaultHeadersRequestHandler]
        )
    }
}
