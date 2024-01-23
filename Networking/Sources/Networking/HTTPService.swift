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

    /// Performs a network request.
    ///
    /// This method should only be used in instances where extensive customization of the underlying
    /// network request needs to be made. In most use cases, the ``send(_:)`` method will provide
    /// the best experience.
    ///
    /// - Parameters:
    ///   - httpRequest: The http request to perform.
    ///   - validate: An optional validation block that will be executed after the request has been
    ///     completed, but before the response handlers have processed the response.
    ///   - shouldRetryIfUnauthorized: A flag indicating if this request should be retried when an
    ///     authentication error is encountered. If true, the token provider will be used to refresh
    ///     the token before attempting the network request again. If authentication fails a second
    ///     time this method will throw the authentication error.
    /// - Returns: The http response received for the request.
    ///
    ///
    public func send(
        _ httpRequest: HTTPRequest,
        validate: ((HTTPResponse) throws -> Void)? = nil,
        shouldRetryIfUnauthorized: Bool = false
    ) async throws -> HTTPResponse {
        var httpRequest = httpRequest
        try await applyRequestHandlers(&httpRequest)
        logger.logRequest(httpRequest)

        var httpResponse = try await client.send(httpRequest)
        logger.logResponse(httpResponse)

        if let tokenProvider, httpResponse.statusCode == 401, shouldRetryIfUnauthorized {
            try await tokenProvider.refreshToken()

            // Send the request again, but don't retry if still unauthorized to prevent a retry loop.
            return try await send(httpRequest, validate: validate, shouldRetryIfUnauthorized: false)
        }
        try validate?(httpResponse)
        try await applyResponseHandlers(&httpResponse)
        return httpResponse
    }

    // MARK: Private Methods

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
        let httpRequest = try HTTPRequest(request: request, baseURL: baseURL)

        let httpResponse = try await send(
            httpRequest,
            validate: request.validate,
            shouldRetryIfUnauthorized: shouldRetryIfUnauthorized
        )

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
