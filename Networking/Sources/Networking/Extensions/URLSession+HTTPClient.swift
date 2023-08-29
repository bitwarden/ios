import Foundation

/// Conforms `URLSession` to the `HTTPClient` protocol.
///
extension URLSession: HTTPClient {
    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        for (field, value) in request.headers {
            urlRequest.addValue(value, forHTTPHeaderField: field)
        }

        let (data, urlResponse) = try await data(for: urlRequest)

        return try HTTPResponse(data: data, response: urlResponse, request: request)
    }
}
