import Networking
import UIKit

/// A service used by the application to make API requests.
///
class APIService {
    // MARK: Properties

    /// The API service that is used for general requests.
    let apiService: HTTPService

    /// The API service used for logging events.
    let eventsService: HTTPService

    /// The API service used for user identity requests.
    let identityService: HTTPService

    // MARK: Initialization

    /// Initialize an `APIService` used to make API requests.
    ///
    /// - Parameter client: The underlying `HTTPClient` that performs the network request. Defaults
    ///     to `URLSession.shared`.
    ///
    init(client: HTTPClient = URLSession.shared) {
        let defaultHeadersRequestHandler = DefaultHeadersRequestHandler(
            appName: Bundle.main.appName,
            appVersion: Bundle.main.appVersion,
            buildNumber: Bundle.main.buildNumber,
            systemDevice: UIDevice.current
        )

        apiService = HTTPService(
            baseURL: URL(string: "https://vault.bitwarden.com/api")!,
            client: client,
            requestHandlers: [defaultHeadersRequestHandler]
        )
        eventsService = HTTPService(
            baseURL: URL(string: "https://vault.bitwarden.com/events")!,
            client: client,
            requestHandlers: [defaultHeadersRequestHandler]
        )
        identityService = HTTPService(
            baseURL: URL(string: "https://vault.bitwarden.com/identity")!,
            client: client,
            requestHandlers: [defaultHeadersRequestHandler]
        )
    }
}
