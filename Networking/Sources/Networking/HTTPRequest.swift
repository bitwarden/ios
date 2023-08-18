import Foundation

/// A data model containing the details of an HTTP request to be performed.
///
public struct HTTPRequest: Equatable {
    // MARK: Properties

    /// Data to be sent in the body of the request.
    public let body: Data?

    /// Headers to be included in the request.
    public let headers: [String: String]

    /// The HTTP method of the request.
    public let method: HTTPMethod

    /// A unique identifier for the request.
    public let requestID: UUID

    /// The URL for the request.
    public let url: URL

    // MARK: Initialization

    /// Initialize a `HTTPRequest`.
    ///
    /// - Parameters:
    ///   - url: The URL for the request.
    ///   - method: The HTTP method of the request.
    ///   - headers: Headers to be included in the request.
    ///   - body: Data to be sent in the body of the request.
    ///   - requestID: A unique identifier for the request.
    ///
    public init(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil,
        requestID: UUID = UUID()
    ) {
        self.body = body
        self.headers = headers
        self.method = method
        self.requestID = requestID
        self.url = url
    }
}

public extension HTTPRequest {
    /// Initialize a `HTTPRequest` from a `Request` instance.
    ///
    /// - Parameters:
    ///   - request: The `Request` instance used to initialize the `HTTPRequest`.
    ///   - baseURL: The base URL that will be prepended to the `Request`'s path to construct the
    ///     request URL.
    ///
    init<R: Request>(request: R, baseURL: URL) throws {
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = !request.query.isEmpty ? request.query : nil

        if urlComponents.path.hasSuffix("/") {
            urlComponents.path.removeLast()
        }

        guard let url = urlComponents.url?.appendingPathComponent(request.path) else {
            fatalError("🛑 Request `resolve` failed: reason unknown.")
        }

        var headers = request.headers
        if let additionalHeaders = request.body?.additionalHeaders {
            for header in additionalHeaders {
                headers[header.key] = header.value
            }
        }

        try self.init(
            url: url,
            method: request.method,
            headers: headers,
            body: request.body?.encode()
        )
    }
}
