import Foundation

/// A protocol for a networking client that performs HTTP requests.
///
public protocol HTTPClient {
    /// Download and store the data from a `URLRequest`.
    ///
    /// - Parameter urlRequest: The `URLRequest` where the downloadable data is located.
    ///
    /// - Returns: The `URL` temporary location of the file.
    ///
    func download(from urlRequest: URLRequest) async throws -> URL

    /// Sends a `HTTPRequest` over the network, returning a `HTTPResponse`.
    ///
    /// - Parameter request: The `HTTPRequest` to send.
    /// - Returns: A `HTTPResponse` containing the data that was returned from the network request.
    ///
    func send(_ request: HTTPRequest) async throws -> HTTPResponse
}
