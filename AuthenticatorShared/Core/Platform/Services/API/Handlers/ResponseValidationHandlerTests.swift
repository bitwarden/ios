import Networking
import XCTest

@testable import AuthenticatorShared

class ResponseValidationHandlerTests: AuthenticatorTestCase {
    // MARK: Properties

    var subject: ResponseValidationHandler!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = ResponseValidationHandler()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `handle(_:)` doesn't throw an error for successful status codes.
    func test_handle_validResponse() async throws {
        for statusCode in [200, 250, 299] {
            var response = HTTPResponse.success(statusCode: statusCode)
            let handledResponse = try await subject.handle(&response)
            XCTAssertEqual(handledResponse, response)
        }
    }

    /// `handle(_:)` throws a `ServerError` if the response is able to be parsed as a `ErrorResponseModel`.
    func test_handle_throwsServerError() async throws {
        var response = HTTPResponse.failure(statusCode: 400, body: APITestData.bitwardenErrorMessage.data)

        try await assertAsyncThrows(error: ServerError.error(errorResponse: ErrorResponseModel(response: response))) {
            _ = try await subject.handle(&response)
        }
    }

    /// `handle(_:)` throws a `ResponseValidationError` for any non-2XX status codes that aren't
    /// able to be parsed as a `ErrorResponseModel`.
    func test_handle_throwsResponseValidationError() async {
        for statusCode in [400, 499, 500, 599] {
            var response = HTTPResponse.failure(statusCode: statusCode)
            await assertAsyncThrows(error: ResponseValidationError(response: response)) {
                _ = try await subject.handle(&response)
            }
        }
    }
}
