import Foundation
import Networking

public extension Result where Success == HTTPResponse, Error: Error {
    /// Convenience method to get a successful HTTPResponse result with APITestData.
    static func httpSuccess(testData: APITestData) -> Result<HTTPResponse, Error> {
        let response = HTTPResponse.success(
            body: testData.data,
        )
        return .success(response)
    }

    /// Convenience method to get a successful result with a failed HTTPResponse.
    static func httpFailure(
        statusCode: Int = 500,
        headers: [String: String] = [:],
        data: Data = Data(),
    ) -> Result<HTTPResponse, Error> {
        let response = HTTPResponse.failure(
            statusCode: statusCode,
            headers: headers,
            body: data,
        )
        return .success(response)
    }

    /// Convenience method to get a failed HTTPResponse result.
    static func httpFailure(_ error: Error) -> Result<HTTPResponse, Error> {
        .failure(error)
    }
}
