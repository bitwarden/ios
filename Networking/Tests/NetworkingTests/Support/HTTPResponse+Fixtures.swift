import Foundation

@testable import Networking

extension HTTPResponse {
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
