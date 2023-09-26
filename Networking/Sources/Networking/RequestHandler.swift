/// A protocol for an object that can view or modify `HTTPRequest` objects before they are sent by
/// the `HTTPClient`.
///
public protocol RequestHandler {
    /// Handles receiving a `HTTPRequest`. The handler can view or modify the request before
    /// returning it to continue to handler chain.
    ///
    /// - Parameter request: The `HTTPRequest` that will be sent by the `HTTPClient`.
    /// - Returns: The original or modified `HTTPRequest`.
    ///
    func handle(_ request: inout HTTPRequest) async throws -> HTTPRequest
}
