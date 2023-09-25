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

    /// A list of `RequestHandler`s that have the option to view or modify the request prior to it
    /// being sent. Handlers are applied in the order of the items in the handler list.
    let requestHandlers: [RequestHandler]

    /// A list of `ResponseHandler`s that have the option to view or modify the response prior to
    /// it being parsed and returned to the caller. Handlers are applied in the order of the items
    /// in the handler list.
    let responseHandlers: [ResponseHandler]

    // MARK: Initialization

    /// Initialize a `HTTPService`.
    ///
    /// - Parameters:
    ///   - baseURL: The URL against which requests are resolved.
    ///   - client: The underlying `HTTPClient` that performs the network request.
    ///   - requestHandlers: A list of `RequestHandler`s that have the option to view or modify the
    ///     request prior to it being sent.
    ///   - responseHandlers: A list of `ResponseHandler`s that have the option to view or modify
    ///     the response prior to it being parsed and returned to the caller.
    ///
    public init(
        baseURL: URL,
        client: HTTPClient = URLSession.shared,
        requestHandlers: [RequestHandler] = [],
        responseHandlers: [ResponseHandler] = []
    ) {
        self.baseURL = baseURL
        self.client = client
        self.requestHandlers = requestHandlers
        self.responseHandlers = responseHandlers
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
        var httpRequest = try HTTPRequest(request: request, baseURL: baseURL)
        logger.logRequest(httpRequest)
        for handler in requestHandlers {
            httpRequest = try await handler.handle(&httpRequest)
        }

        var httpResponse = try await client.send(httpRequest)

        logger.logResponse(httpResponse)

        try request.validate(httpResponse)

        for handler in responseHandlers {
            httpResponse = try await handler.handle(&httpResponse)
        }

        return try R.Response(response: httpResponse)
    }
}
