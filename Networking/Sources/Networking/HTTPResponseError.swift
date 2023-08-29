import Foundation

/// Errors thrown by `HTTPResponse`.
///
enum HTTPResponseError: Error, Equatable {
    /// The `URLResponse` was unable to be converted to a `HTTPURLResponse`.
    case invalidResponse(URLResponse)
    /// The `URLResponse` didn't contain a URL.
    case noURL
}
