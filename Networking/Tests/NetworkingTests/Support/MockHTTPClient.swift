@testable import Networking

class MockHTTPClient: HTTPClient {
    var requests = [HTTPRequest]()
    var result: Result<HTTPResponse, Error>?

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        requests.append(request)
        guard let result else {
            throw MockClientError.noResultForRequest
        }
        return try result.get()
    }
}

enum MockClientError: Error {
    case noResultForRequest
}
