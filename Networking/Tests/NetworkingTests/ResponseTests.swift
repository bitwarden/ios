import XCTest

@testable import Networking

class ResponseTests: XCTestCase {
    /// Test creating a `Response` from JSON.
    func test_jsonresponse() throws {
        let httpResponse = HTTPResponse(
            url: URL(string: "http://example.com")!,
            statusCode: 200,
            headers: [:],
            body: "{ \"field\": \"value\" }".data(using: .utf8)!,
            requestID: UUID()
        )
        let response = try TestJSONResponse(response: httpResponse)
        XCTAssertEqual(response.field, "value")
    }

    /// Test creating a `Response` from a JSON array.
    func test_jsonresponse_array() throws {
        let httpResponse = HTTPResponse(
            url: URL(string: "http://example.com")!,
            statusCode: 200,
            headers: [:],
            body: "[{ \"field\": \"value\" }]".data(using: .utf8)!,
            requestID: UUID()
        )
        let response = try [TestJSONResponse](response: httpResponse)
        XCTAssertEqual(response.count, 1)
        XCTAssertEqual(response[0].field, "value")
    }
}
