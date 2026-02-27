/// A protocol for an object that can view or modify `HTTPResponse` objects after they are received
/// by the `HTTPClient` but before they are parsed into response objects and returned to the caller.
///
public protocol ResponseHandler: Sendable {
    /// Handles receiving a `HTTPResponse`. The handler can view or modify the response before
    /// returning it to continue to handler chain.
    ///
    /// - Parameters:
    ///   - response: The `HTTPResponse` that was received by the `HTTPClient`.
    ///   - request: The original `HTTPRequest` that produced this response.
    ///   - retryWith: An optional closure that re-sends a request through the full `HTTPService`
    ///     pipeline (request handlers, logging, token refresh, and subsequent response handlers).
    ///     Pass `nil` when redirect-following has already been attempted for this call chain, to
    ///     prevent infinite recursion. Handlers that do not need to re-send a request can ignore
    ///     this parameter.
    /// - Returns: The original or modified `HTTPResponse`.
    ///
    func handle(
        _ response: inout HTTPResponse,
        for request: HTTPRequest,
        retryWith: ((HTTPRequest) async throws -> HTTPResponse)?,
    ) async throws -> HTTPResponse
}
