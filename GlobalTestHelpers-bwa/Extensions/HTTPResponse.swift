import Foundation
import Networking

extension HTTPResponse {
    /// Creates a successful `HTTPResponse` for testing purposes.
    ///
    /// - Parameters:
    ///   - string: A string version of the `URL` for this response. Defaults to `http://example.com`.
    ///   - statusCode: The status code for this response. Defaults to `200`.
    ///   - headers: The headers for this response. Defaults to `[:]`.
    ///   - body: The body for this response. Defaults to an empty `Data` object.
    /// - Returns: Returns a `HTTPResponse` with the parameters provided.
    ///
    static func success(
        string: String = "http://example.com",
        statusCode: Int = 200,
        headers: [String: String] = [:],
        body: Data = Data()
    ) -> HTTPResponse {
        HTTPResponse(
            url: URL(string: string)!,
            statusCode: statusCode,
            headers: headers,
            body: body,
            requestID: UUID()
        )
    }

    /// Creates a failure `HTTPResponse` for testing purposes.
    ///
    /// - Parameters:
    ///   - string: A string version of the `URL` for this response. Defaults to `http://example.com`.
    ///   - statusCode: The status code for this response. Defaults to `500`.
    ///   - headers: The headers for this response. Defaults to `[:]`.
    ///   - body: The body for this response. Defaults to an empty `Data` object.
    /// - Returns: Returns a `HTTPResponse` with the parameters provided.
    ///
    static func failure(
        string: String = "http://example.com",
        statusCode: Int = 500,
        headers: [String: String] = [:],
        body: Data = Data()
    ) -> HTTPResponse {
        HTTPResponse(
            url: URL(string: string)!,
            statusCode: statusCode,
            headers: headers,
            body: body,
            requestID: UUID()
        )
    }
}
