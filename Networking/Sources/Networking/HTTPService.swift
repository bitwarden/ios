import Foundation

/// A networking service that can be used to perform HTTP requests.
///
public class HTTPService {
    // MARK: Properties

    /// The URL against which requests are resolved.
    var baseURL: URL { baseUrlGetter() }

    /// A getter function for dynamically retrieving the base url against which requests are resolved.
    let baseUrlGetter: () -> URL

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

    /// An object used to get an access token and refresh it when necessary.
    let tokenProvider: TokenProvider?

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
    ///   - tokenProvider: An object used to get an access token and refresh it when necessary.
    ///
    public init(
        baseURL: URL,
        client: HTTPClient = URLSession.shared,
        requestHandlers: [RequestHandler] = [],
        responseHandlers: [ResponseHandler] = [],
        tokenProvider: TokenProvider? = nil
    ) {
        baseUrlGetter = { baseURL }
        self.client = client
        self.requestHandlers = requestHandlers
        self.responseHandlers = responseHandlers
        self.tokenProvider = tokenProvider
    }

    /// Initialize a `HTTPService`.
    ///
    /// - Parameters:
    ///   - baseUrlGetter: A getter function for dynamically retrieving the base url against which
    ///     requests are resolved.
    ///   - client: The underlying `HTTPClient` that performs the network request.
    ///   - requestHandlers: A list of `RequestHandler`s that have the option to view or modify the
    ///     request prior to it being sent.
    ///   - responseHandlers: A list of `ResponseHandler`s that have the option to view or modify
    ///     the response prior to it being parsed and returned to the caller.
    ///   - tokenProvider: An object used to get an access token and refresh it when necessary.
    ///
    public init(
        baseUrlGetter: @escaping () -> URL,
        client: HTTPClient = URLSession.shared,
        requestHandlers: [RequestHandler] = [],
        responseHandlers: [ResponseHandler] = [],
        tokenProvider: TokenProvider? = nil
    ) {
        self.baseUrlGetter = baseUrlGetter
        self.client = client
        self.requestHandlers = requestHandlers
        self.responseHandlers = responseHandlers
        self.tokenProvider = tokenProvider
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
        try await send(request, shouldRetryIfUnauthorized: true)
    }

    // MARK: Private

    /// Performs a network request.
    ///
    /// - Parameters:
    ///   - request: The request to perform.
    ///   - shouldRetryIfUnauthorized: Whether the request should be retried if a token provider is
    ///     used and the response status code is 401 Unauthorized.
    /// - Returns: The response received for the request.
    ///
    private func send<R: Request>(
        _ request: R,
        shouldRetryIfUnauthorized: Bool
    ) async throws -> R.Response where R.Response: Response {
        var httpRequest = try HTTPRequest(request: request, baseURL: baseURL)
        logger.logRequest(httpRequest)
        try await applyRequestHandlers(&httpRequest)

        var httpResponse = try await client.send(httpRequest)
        logger.logResponse(httpResponse)

        if let tokenProvider, httpResponse.statusCode == 401, shouldRetryIfUnauthorized {
            try await tokenProvider.refreshToken()

            // Send the request again, but don't retry if still unauthorized to prevent a retry loop.
            return try await send(request, shouldRetryIfUnauthorized: false)
        }
        try request.validate(httpResponse)
        try await applyResponseHandlers(&httpResponse)

        return try R.Response(response: httpResponse)
    }

    /// Applies any request handlers to the request before it is sent.
    ///
    /// - Parameter httpRequest: The request to apply request handlers to.
    ///
    private func applyRequestHandlers(_ httpRequest: inout HTTPRequest) async throws {
        for handler in requestHandlers {
            httpRequest = try await handler.handle(&httpRequest)
        }

        if let tokenProvider {
            try await httpRequest.headers["Authorization"] = "Bearer \(tokenProvider.getToken())"
        }
    }

    /// Applies any response handlers to the response after it's been received.
    ///
    /// - Parameter httpResponse: The response to apply response handlers to.
    ///
    private func applyResponseHandlers(_ httpResponse: inout HTTPResponse) async throws {
        for handler in responseHandlers {
            httpResponse = try await handler.handle(&httpResponse)
        }
    }
}
