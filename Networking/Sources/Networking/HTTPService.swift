import Foundation

/// A networking service that can be used to perform HTTP requests.
///
public class HTTPService {
    // MARK: Properties

    /// The URL against which requests are resolved.
    let baseURL: URL

    /// The underlying `HTTPClient` that performs the network request.
    let client: HTTPClient

    /// A logger used to log HTTP request and responses.
    let logger = HTTPLogger()

    // MARK: Initialization

    /// Initialize a `HTTPService`.
    ///
    /// - Parameters:
    ///   - baseURL: The URL against which requests are resolved.
    ///   - client: The underlying `HTTPClient` that performs the network request.
    ///
    public init(
        baseURL: URL,
        client: HTTPClient = URLSession.shared
    ) {
        self.baseURL = baseURL
        self.client = client
    }

    // MARK: Request Performing

    /// Performs a network request.
    ///
    /// - Parameter request: The request to perform.
    /// - Returns: The response received for the request.
    ///
    public func send<R: Request>(
        _ request: R
    ) async throws -> R.Response where R.Response: Response {
        let httpRequest = try HTTPRequest(request: request, baseURL: baseURL)
        logger.logRequest(httpRequest)

        let httpResponse = try await client.send(httpRequest)
        logger.logResponse(httpResponse)

        return try R.Response(response: httpResponse)
    }
}
