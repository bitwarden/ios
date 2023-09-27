import Foundation
import Networking

extension Result where Success == HTTPResponse, Error: Error {
    static func httpSuccess(testData: APITestData) -> Result<HTTPResponse, Error> {
        let response = HTTPResponse.success(
            body: testData.data
        )
        return .success(response)
    }

    static func httpFailure(
        statusCode: Int = 500,
        headers: [String: String] = [:],
        data: Data = Data()
    ) -> Result<HTTPResponse, Error> {
        let response = HTTPResponse.failure(
            statusCode: statusCode,
            headers: headers,
            body: data
        )
        return .success(response)
    }

    static func httpFailure(_ error: Error) -> Result<HTTPResponse, Error> {
        .failure(error)
    }
}
