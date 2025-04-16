import BitwardenKit
import Networking
import UIKit

/// A service used by the application to make API requests.
///
class APIService {
    // MARK: Properties

    /// The API service that is used for general unauthenticated requests.
    let apiUnauthenticatedService: HTTPService

    // MARK: Private Properties

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
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        client: HTTPClient = URLSession.shared
    ) {
        self.client = client

        defaultHeadersRequestHandler = DefaultHeadersRequestHandler(
            appName: "Bitwarden_Mobile",
            appVersion: Bundle.main.appVersion,
            buildNumber: Bundle.main.buildNumber,
            systemDevice: UIDevice.current
        )

        apiUnauthenticatedService = HTTPService(
            baseURLGetter: { URL(string: "https://api.bitwarden.com")! },
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
            responseHandlers: [responseValidationHandler]
        )
    }
}
