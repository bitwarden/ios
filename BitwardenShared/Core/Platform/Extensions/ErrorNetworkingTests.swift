import Networking
import XCTest

@testable import BitwardenShared

class ErrorNetworkingTests: BitwardenTestCase {
    // MARK: Tests

    /// `isNetworkingError` returns `false` for non-networking errors.
    func test_isNetworkingError_other() {
        struct NonNetworkingError: Error {}

        XCTAssertFalse(NonNetworkingError().isNetworkingError)
    }

    /// `isNetworkingError` returns `true` for `ResponseValidationError`s.
    func test_isNetworkingError_responseValidationError() {
        let response = HTTPResponse.failure(statusCode: 500)
        let error = ResponseValidationError(response: response)

        XCTAssertTrue(error.isNetworkingError)
    }

    /// `isNetworkingError` returns `true` for `ServerError`s.
    func test_isNetworkingError_serverError() throws {
        let response = HTTPResponse.failure(statusCode: 400, body: APITestData.bitwardenErrorMessage.data)
        let error = try ServerError.error(errorResponse: ErrorResponseModel(response: response))

        XCTAssertTrue(error.isNetworkingError)
    }

    /// `isNetworkingError` returns `true` for `URLError`s.
    func test_isNetworkingError_urlError() throws {
        XCTAssertTrue(URLError(.cancelled).isNetworkingError)
        XCTAssertTrue(URLError(.networkConnectionLost).isNetworkingError)
        XCTAssertTrue(URLError(.timedOut).isNetworkingError)
    }
}
