import Foundation
import Networking

extension Result where Success == HTTPResponse, Error: Error {
    static func httpSuccess(testData: APITestData) -> Result<HTTPResponse, Error> {
        let response = HTTPResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            headers: [:],
            body: testData.data,
            requestID: UUID()
        )
        return .success(response)
    }

    static func httpFailure(
        statusCode: Int = 500,
        headers: [String: String] = [:],
        data: Data = Data()
    ) -> Result<HTTPResponse, Error> {
        let response = HTTPResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            headers: headers,
            body: data,
            requestID: UUID()
        )
        return .success(response)
    }

    static func httpFailure(_ error: Error) -> Result<HTTPResponse, Error> {
        .failure(error)
    }
}
