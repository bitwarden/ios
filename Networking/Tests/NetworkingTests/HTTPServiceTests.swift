import XCTest

@testable import Networking

class HTTPServiceTests: XCTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: HTTPService!

    // MARK: Setup & Teardown

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

    // MARK: Tests

    /// `send(_:)` forwards the request to the client and returns the response.
    func test_sendRequest() async throws {
        let httpResponse = HTTPResponse.success()
        client.result = .success(httpResponse)

        let response = try await subject.send(TestRequest())

        XCTAssertEqual(response.httpResponse, httpResponse)
    }

    /// `send(_:)` applies any request handlers to the request in the order of the array.
    func test_sendRequest_appliesRequestHandlers() async throws {
        let requestHandlerA = TestRequestHandler { request in
            request.headers["RequestHandlerA"] = "🔑"
        }

        let requestHandlerB = TestRequestHandler { request in
            request.headers["RequestHandlerB"] = "🔒"
        }

        subject = HTTPService(
            baseURL: URL(string: "https://example.com")!,
            client: client,
            requestHandlers: [requestHandlerA, requestHandlerB]
        )

        let httpResponse = HTTPResponse.success()
        client.result = .success(httpResponse)
        _ = try await subject.send(TestRequest())

        let request = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(
            request.headers,
            [
                "RequestHandlerA": "🔑",
                "RequestHandlerB": "🔒",
            ]
        )

        XCTAssertNotNil(requestHandlerA.handledRequest)
        XCTAssertEqual(requestHandlerA.handledRequest?.headers, [:])
        XCTAssertNotNil(requestHandlerB.handledRequest)
        XCTAssertEqual(requestHandlerB.handledRequest?.headers, ["RequestHandlerA": "🔑"])
    }

    /// `send(_:)` applies any response handlers to the response in the order of the array.
    func test_sendRequest_appliesResponseHandlers() async throws {
        var responseHandlerActions: [String] = []
        let responseHandlerA = TestResponseHandler { _ in responseHandlerActions.append("ResponseHandlerA") }
        let responseHandlerB = TestResponseHandler { _ in responseHandlerActions.append("ResponseHandlerB") }

        subject = HTTPService(
            baseURL: URL(string: "https://example.com")!,
            client: client,
            responseHandlers: [responseHandlerA, responseHandlerB]
        )

        let httpResponse = HTTPResponse.success()
        client.result = .success(httpResponse)
        _ = try await subject.send(TestRequest())

        XCTAssertEqual(responseHandlerActions, ["ResponseHandlerA", "ResponseHandlerB"])
    }

    /// `send(_:)` forwards the request to the client and throws if an error occurs.
    func test_sendRequest_error() async {
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
