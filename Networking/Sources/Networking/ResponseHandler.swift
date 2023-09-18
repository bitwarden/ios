/// A protocol for an object that can view or modify `HTTPResponse` objects after they are received
/// by the `HTTPClient` but before they are parsed into response objects and returned to the caller.
///
public protocol ResponseHandler {
    /// Handles receiving a `HTTPResponse`. The handler can view or modify the response before
    /// returning it to continue to handler chain.
    ///
    /// - Parameter response: The `HTTPResponse` that was received by the `HTTPClient`.
    /// - Returns: The original or modified `HTTPResponse`.
    ///
    func handle(_ response: inout HTTPResponse) async throws -> HTTPResponse
}
