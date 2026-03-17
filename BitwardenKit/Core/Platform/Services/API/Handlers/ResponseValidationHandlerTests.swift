import Networking
import TestHelpers
import XCTest

@testable import BitwardenKit

class ResponseValidationHandlerTests: BitwardenTestCase {
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

    /// `handle(_:for:retryWith:)` doesn't throw an error for successful status codes.
    func test_handle_validResponse() async throws {
        let request = HTTPRequest(url: URL(string: "https://example.com")!)
        for statusCode in [200, 250, 299] {
            var response = HTTPResponse.success(statusCode: statusCode)
            let handledResponse = try await subject.handle(&response, for: request, retryWith: nil)
            XCTAssertEqual(handledResponse, response)
        }
    }

    /// `handle(_:for:retryWith:)` throws a `ServerError` if the response can be parsed as an `ErrorResponseModel`.
    func test_handle_throwsServerError() async throws {
        let request = HTTPRequest(url: URL(string: "https://example.com")!)
        var response = HTTPResponse.failure(statusCode: 400, body: APITestData.bitwardenErrorMessage.data)

        try await assertAsyncThrows(error: ServerError.error(errorResponse: ErrorResponseModel(response: response))) {
            _ = try await subject.handle(&response, for: request, retryWith: nil)
        }
    }

    /// `handle(_:for:retryWith:)` throws a `ResponseValidationError` for any non-2XX status codes that
    /// aren't able to be parsed as an `ErrorResponseModel`.
    func test_handle_throwsResponseValidationError() async {
        let request = HTTPRequest(url: URL(string: "https://example.com")!)
        for statusCode in [400, 499, 500, 599] {
            var response = HTTPResponse.failure(statusCode: statusCode)
            await assertAsyncThrows(error: ResponseValidationError(response: response)) {
                _ = try await subject.handle(&response, for: request, retryWith: nil)
            }
        }
    }
}
