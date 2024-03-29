import Foundation

// MARK: - Request

/// A protocol for an instance that describes an HTTP request.
///
public protocol Request {
    // MARK: Types

    /// The response type associated with this request.
    associatedtype Response

    /// The body type associated with this request. This could be `Data` or another type conforming
    /// to `RequestBody` that could be converted to `Data` to include in the body of the request.
    associatedtype Body: RequestBody

    // MARK: Properties

    /// The HTTP method for the request.
    var method: HTTPMethod { get }

    /// The body of the request.
    ///
    /// Note: This type _must_ be optional in your request type, or else the default `nil` value found below
    /// will be used during encoding. If you don't want this value to be optional, create an initializer where
    /// the type is non-optional.
    var body: Body? { get }

    /// The URL path for this request that will be appended to the base URL.
    var path: String { get }

    /// A dictionary of HTTP headers to be sent in the request.
    var headers: [String: String] { get }

    /// A list of URL query items for the request.
    var query: [URLQueryItem] { get }

    // MARK: Methods

    /// Validates the response for this request.
    ///
    /// For example, this method can be used to catch status code errors, or errors that are contained within
    /// the response's `body`.
    ///
    /// - Parameter response: The `HTTPResponse` that should be validated for this request.
    /// - Throws: Throws an error if validation fails.
    ///
    func validate(_ response: HTTPResponse) throws
}

/// This extension provides default values for the `Request` methods, which can be overridden in a
/// type conforming to the `Request` protocol.
///
public extension Request {
    /// The HTTP method for the request.
    var method: HTTPMethod { .get }

    /// The body of the request.
    var body: Data? { nil }

    /// A dictionary of HTTP headers to be sent in the request.
    var headers: [String: String] { [:] }

    /// A list of URL query items for the request.
    var query: [URLQueryItem] { [] }

    /// Validates the response for this request.
    ///
    /// - Parameter response: The `HTTPResponse` that should be validated for this request.
    /// - Returns: The validated `HTTPResponse`.
    /// - Throws: Throws an error if validation fails.
    ///
    func validate(_ response: HTTPResponse) throws {}
}
