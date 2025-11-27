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
    ///   - flightRecorder: The service used by the application for recording temporary debug logs.
    ///
    init(
        client: HTTPClient = URLSession.shared,
        environmentService: EnvironmentService,
        flightRecorder: FlightRecorder,
    ) {
        self.client = client

        defaultHeadersRequestHandler = DefaultHeadersRequestHandler(
            appName: "Bitwarden_Authenticator_Mobile",
            appVersion: Bundle.main.appVersion,
            buildNumber: Bundle.main.buildNumber,
            systemDevice: UIDevice.current,
        )

        apiUnauthenticatedService = HTTPService(
            baseURLGetter: { environmentService.apiURL },
            client: client,
            loggers: [
                FlightRecorderHTTPLogger(flightRecorder: flightRecorder),
            ],
            requestHandlers: [defaultHeadersRequestHandler],
            responseHandlers: [responseValidationHandler],
        )
    }
}
