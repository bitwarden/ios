/// A protocol for a networking client that performs HTTP requests.
///
public protocol HTTPClient {
    /// Sends a `HTTPRequest` over the network, returning a `HTTPResponse`.
    ///
    /// - Parameter request: The `HTTPRequest` to send.
    /// - Returns: A `HTTPResponse` containing the data that was returned from the network request.
    ///
    func send(_ request: HTTPRequest) async throws -> HTTPResponse
}
