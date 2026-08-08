import BitwardenKit
import Networking

// MARK: - CustomHeadersRequestHandler

/// A `RequestHandler` that applies the user's custom headers to requests sent to the environment's
/// hosts. Requests to other hosts (e.g. HIBP) are left untouched so the headers, which may contain
/// credentials such as Cloudflare Access tokens, are never sent to third parties.
///
/// `@unchecked Sendable` because the stored services are immutable references whose
/// implementations synchronize their own mutable state.
///
final class CustomHeadersRequestHandler: RequestHandler, @unchecked Sendable {
    // MARK: Private Properties

    /// The service used to get the custom headers for the current environment.
    private let customHeadersService: CustomHeadersService

    /// The service used to determine the environment's hosts.
    private let environmentService: EnvironmentService

    /// The hosts of the current environment's URLs, to which custom headers may be applied.
    private var environmentHosts: Set<String> {
        let urls = [
            environmentService.apiURL,
            environmentService.baseURL,
            environmentService.eventsURL,
            environmentService.iconsURL,
            environmentService.identityURL,
            environmentService.webVaultURL,
        ]
        return Set(urls.compactMap(\.host))
    }

    // MARK: Initialization

    /// Initializes a `CustomHeadersRequestHandler`.
    ///
    /// - Parameters:
    ///   - customHeadersService: The service used to get the custom headers for the current environment.
    ///   - environmentService: The service used to determine the environment's hosts.
    ///
    init(customHeadersService: CustomHeadersService, environmentService: EnvironmentService) {
        self.customHeadersService = customHeadersService
        self.environmentService = environmentService
    }

    // MARK: Request Handler

    func handle(_ request: inout HTTPRequest) async throws -> HTTPRequest {
        let headers = await customHeadersService.getCustomHeaders()
        guard !headers.isEmpty,
              let host = request.url.host,
              environmentHosts.contains(host)
        else {
            return request
        }

        for (name, value) in headers {
            request.headers[name] = value
        }

        return request
    }
}
