import XCTest

@testable import Networking

class HTTPServiceTests: XCTestCase {
    var client: MockHTTPClient!
    var subject: HTTPService!

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()

        subject = HTTPService(
            baseURL: URL(string: "https://example.com")!,
            client: client
        )
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        subject = nil
    }

    /// `send(_:)` forwards the request to the client and returns the response.
    func testSendRequest() async throws {
        let httpResponse = HTTPResponse.success()
        client.result = .success(httpResponse)

        let response = try await subject.send(TestRequest())

        XCTAssertEqual(response.httpResponse, httpResponse)
    }

    /// `send(_:)` forwards the request to the client and throws if an error occurs.
    func testSendRequestError() async {
        client.result = .failure(RequestError())

        do {
            _ = try await subject.send(TestRequest())
            XCTFail("Expected send(_:) to throw an error")
        } catch {
            XCTAssertTrue(error is RequestError)
        }
    }
}

private struct RequestError: Error {}
