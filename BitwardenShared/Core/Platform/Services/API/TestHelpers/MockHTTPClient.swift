import Foundation
import Networking

/// An `HTTPClient` that can be used to return mocked responses.
///
class MockHTTPClient: HTTPClient {
    // MARK: Properties

    /// A list of download requests that have been received by the HTTP client.
    var downloadRequests: [URLRequest] = []

    /// A list of download results that will be returned in order for future requests.
    var downloadResults: [Result<URL, Error>] = []

    /// A list of requests that have been received by the HTTP client.
    var requests: [HTTPRequest] = []

    /// Gets the next result or sets a single result for the HTTP client to return for the next request.
    var result: Result<HTTPResponse, Error>? {
        get {
            results.first
        }
        set {
            guard let newValue else {
                results.removeAll()
                return
            }
            results = [newValue]
        }
    }

    /// A list of results that will be returned in order for future requests.
    var results: [Result<HTTPResponse, Error>] = []

    // MARK: Methods

    /// Sends a download request and returns a mock download response, if one exists.
    ///
    /// - Parameter urlRequest: The url request to make on the client.
    /// - Returns: A mock download response for the request, if one exists.
    ///
    func download(from urlRequest: URLRequest) async throws -> URL {
        downloadRequests.append(urlRequest)

        guard !downloadResults.isEmpty else { throw MockHTTPClientError.noResultForDownloadRequest }

        let result = downloadResults.removeFirst()
        return try result.get()
    }

    /// Sends a request and returns a mock response, if one exists.
    ///
    /// - Parameter request: The request to make on the client.
    /// - Returns: A mock response for the request, if one exists.
    ///
    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        requests.append(request)

        guard !results.isEmpty else { throw MockHTTPClientError.noResultForRequest }

        let result = results.removeFirst()
        return try result.get()
    }
}

/// Errors thrown by `MockHTTPClient`.
enum MockHTTPClientError: Error {
    /// There's no results set for the download request.
    case noResultForDownloadRequest

    /// There's no results set for the request.
    case noResultForRequest
}
