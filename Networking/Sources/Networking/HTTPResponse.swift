import Foundation

/// A data model containing the details of an HTTP response that's been received.
///
public struct HTTPResponse: Equatable {
    // MARK: Properties

    /// Data received in the body of the response.
    public let body: Data

    /// Headers received from response.
    public let headers: [String: String]

    /// The response's status code.
    public let statusCode: Int

    /// A unique identifier for the request associated with this response.
    public let requestID: UUID

    /// The URL from which the response was created.
    public let url: URL

    // MARK: Initialization

    /// Initialize a `HTTPResponse`.
    ///
    /// - Parameters:
    ///   - url: The URL from which the response was created.
    ///   - statusCode: The response's status code.
    ///   - headers: Headers received from response.
    ///   - body: Data received in the body of the response.
    ///   - requestID: A unique identifier for the request associated with this response.
    ///
    public init(url: URL, statusCode: Int, headers: [String: String], body: Data, requestID: UUID) {
        self.body = body
        self.headers = headers
        self.statusCode = statusCode
        self.requestID = requestID
        self.url = url
    }

    /// Initialize a `HTTPResponse` with data and a `URLResponse`.
    ///
    /// - Parameters:
    ///   - data: Data received in the body of the response.
    ///   - response: A `URLResponse` object containing the details of the response.
    ///   - request: The `HTTPRequest` associated with this response.
    ///
    init(data: Data, response: URLResponse, request: HTTPRequest) throws {
        guard let response = response as? HTTPURLResponse else {
            throw HTTPResponseError.invalidResponse(response)
        }

        guard let responseURL = response.url else {
            throw HTTPResponseError.noURL
        }

        url = responseURL
        statusCode = response.statusCode
        body = data
        headers = response.allHeaderFields as? [String: String] ?? [:]
        requestID = request.requestID
    }
}
