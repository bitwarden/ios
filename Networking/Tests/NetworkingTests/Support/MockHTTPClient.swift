import Foundation

@testable import Networking

class MockHTTPClient: HTTPClient {
    var downloadRequests = [URLRequest]()
    var downloadResults = [Result<URL, Error>]()

    var requests = [HTTPRequest]()
    var results = [Result<HTTPResponse, Error>]()

    var result: Result<HTTPResponse, Error>? {
        get { results.first }
        set {
            guard let newValue else {
                results.removeAll()
                return
            }
            results = [newValue]
        }
    }

    func download(from urlRequest: URLRequest) async throws -> URL {
        downloadRequests.append(urlRequest)

        guard !downloadResults.isEmpty else { throw MockClientError.noResultForDownloadRequest }

        let result = downloadResults.removeFirst()
        return try result.get()
    }

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        requests.append(request)

        guard !results.isEmpty else { throw MockClientError.noResultForRequest }

        let result = results.removeFirst()
        return try result.get()
    }
}

enum MockClientError: Error {
    case noResultForDownloadRequest
    case noResultForRequest
}
