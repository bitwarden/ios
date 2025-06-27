import BitwardenKitMocks
import Networking
import TestHelpers
import XCTest

@testable import BitwardenKit

class ErrorNetworkingTests: BitwardenTestCase {
    // MARK: Tests

    /// `isNetworkingError` returns `false` for non-networking errors.
    func test_isNetworkingError_other() {
        struct NonNetworkingError: Error {}

        XCTAssertFalse(NonNetworkingError().isNonLoggableError)
    }

    /// `isNetworkingError` returns `true` for `ResponseValidationError`s.
    func test_isNetworkingError_responseValidationError() {
        let response = HTTPResponse.failure(statusCode: 500)
        let error = ResponseValidationError(response: response)

        XCTAssertTrue(error.isNonLoggableError)
    }

    /// `isNetworkingError` returns `true` for `ServerError`s.
    func test_isNetworkingError_serverError() throws {
        let response = HTTPResponse.failure(statusCode: 400, body: APITestData.bitwardenErrorMessage.data)
        let error = try ServerError.error(errorResponse: ErrorResponseModel(response: response))

        XCTAssertTrue(error.isNonLoggableError)
    }

    /// `isNetworkingError` returns `true` for `URLError`s.
    func test_isNetworkingError_urlError() throws {
        XCTAssertTrue(URLError(.cancelled).isNonLoggableError)
        XCTAssertTrue(URLError(.networkConnectionLost).isNonLoggableError)
        XCTAssertTrue(URLError(.timedOut).isNonLoggableError)
    }

    /// `isNetworkingError` returns `true` for custom `NetworkingError`.
    func test_isNetworkingError_networkingError() throws {
        XCTAssertTrue(TestNetworkingError.test.isNonLoggableError)
    }
}

/// Error to be used as test for `NetworkingError`.
enum TestNetworkingError: NonLoggableError {
    case test
}
