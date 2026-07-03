import XCTest

@testable import Networking

@MainActor
class HTTPServiceTests: XCTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: HTTPService!

    // MARK: Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        client = MockHTTPClient()

        subject = HTTPService(
            baseURL: URL(string: "https://example.com")!,
            client: client,
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()

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
            requestHandlers: [requestHandlerA, requestHandlerB],
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
            ],
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
            responseHandlers: [responseHandlerA, responseHandlerB],
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

    /// `send(_:)` applies the access token from the token provider to requests.
    func test_sendRequest_tokenProvider_appliesAccessToken() async throws {
        let tokenProvider = MockTokenProvider()
        subject = HTTPService(
            baseURL: URL(string: "https://example.com")!,
            client: client,
            tokenProvider: tokenProvider,
        )

        client.result = .success(.success())

        _ = try await subject.send(TestRequest())

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].headers, ["Authorization": "Bearer ACCESS_TOKEN"])
        XCTAssertEqual(tokenProvider.getTokenCallCount, 1)
        XCTAssertEqual(tokenProvider.refreshTokenCallCount, 0)
    }

    /// `send(_:)` throws an error if refreshing the access token results in an error.
    func test_sendRequest_tokenProvider_refreshAccessTokenError() async {
        let tokenProvider = MockTokenProvider()
        subject = HTTPService(
            baseURL: URL(string: "https://example.com")!,
            client: client,
            tokenProvider: tokenProvider,
        )

        client.results = [
            .success(.failure(statusCode: 401)),
        ]

        tokenProvider.tokenResults = [
            .success("ACCESS_TOKEN"),
        ]
        tokenProvider.refreshTokenResult = .failure(RequestError())

        do {
            _ = try await subject.send(TestRequest())
        } catch {
            XCTAssertTrue(error is RequestError)
        }
    }

    /// `send(_:)` doesn't keep trying to refresh the access token if 401 Unauthorized is received
    /// after refreshing the token.
    func test_sendRequest_tokenProvider_refreshAccessTokenUnauthorized() async throws {
        let tokenProvider = MockTokenProvider()
        subject = HTTPService(
            baseURL: URL(string: "https://example.com")!,
            client: client,
            tokenProvider: tokenProvider,
        )

        client.results = [
            .success(.failure(statusCode: 401)),
            .success(.failure(statusCode: 401)),
        ]

        tokenProvider.tokenResults = [
            .success("ACCESS_TOKEN"),
            .success("REFRESHED_ACCESS_TOKEN"),
        ]

        let response = try await subject.send(TestRequest())

        XCTAssertEqual(response.httpResponse.statusCode, 401)
        XCTAssertEqual(tokenProvider.getTokenCallCount, 2)
        XCTAssertEqual(tokenProvider.refreshTokenCallCount, 1)
    }

    /// `send(_:)` doesn't refresh the access token for non-401 status codes.
    func test_sendRequest_tokenProvider_doesNotRefreshTokenForNon401Statuses() async throws {
        let tokenProvider = MockTokenProvider()
        subject = HTTPService(
            baseURL: URL(string: "https://example.com")!,
            client: client,
            tokenProvider: tokenProvider,
        )

        client.result = .success(.failure(statusCode: 500))

        let response = try await subject.send(TestRequest())

        XCTAssertEqual(response.httpResponse.statusCode, 500)
        XCTAssertEqual(tokenProvider.getTokenCallCount, 1)
        XCTAssertEqual(tokenProvider.refreshTokenCallCount, 0)
    }

    /// `send(_:)` refreshes the access token if a 401 Unauthorized error occurs.
    func test_sendRequest_tokenProvider_refreshesAccessToken() async throws {
        let tokenProvider = MockTokenProvider()
        subject = HTTPService(
            baseURL: URL(string: "https://example.com")!,
            client: client,
            tokenProvider: tokenProvider,
        )

        client.results = [
            .success(.failure(statusCode: 401)),
            .success(.success()),
        ]

        tokenProvider.tokenResults = [
            .success("ACCESS_TOKEN"),
            .success("REFRESHED_ACCESS_TOKEN"),
        ]

        _ = try await subject.send(TestRequest())

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].headers, ["Authorization": "Bearer ACCESS_TOKEN"])
        XCTAssertEqual(client.requests[1].headers, ["Authorization": "Bearer REFRESHED_ACCESS_TOKEN"])
        XCTAssertEqual(tokenProvider.getTokenCallCount, 2)
        XCTAssertEqual(tokenProvider.refreshTokenCallCount, 1)
    }

    /// `send(_:)` passes a non-nil `retryWith` to response handlers by default, allowing them to
    /// re-send the request (e.g. after a redirect).
    func test_sendRequest_responseHandler_retryWithProvidedByDefault() async throws {
        var capturedRetryWith: ((HTTPRequest) async throws -> HTTPResponse)?
        let responseHandler = CapturingRetryWithResponseHandler { retryWith in
            capturedRetryWith = retryWith
        }

        subject = HTTPService(
            baseURL: URL(string: "https://example.com")!,
            client: client,
            responseHandlers: [responseHandler],
        )

        client.result = .success(.success())
        _ = try await subject.send(TestRequest())

        XCTAssertNotNil(capturedRetryWith)
    }

    /// `send(_:)` passes `nil` as `retryWith` to response handlers when `shouldFollowRedirect` is
    /// false, preventing recursive redirect-following.
    func test_sendRequest_responseHandler_retryWithNilWhenRedirectDisabled() async throws {
        var capturedRetryWith: ((HTTPRequest) async throws -> HTTPResponse)?
        let responseHandler = CapturingRetryWithResponseHandler { retryWith in
            capturedRetryWith = retryWith
        }

        subject = HTTPService(
            baseURL: URL(string: "https://example.com")!,
            client: client,
            responseHandlers: [responseHandler],
        )

        client.result = .success(.success())
        let httpRequest = HTTPRequest(url: URL(string: "https://example.com")!)
        _ = try await subject.send(httpRequest, shouldFollowRedirect: false)

        XCTAssertNil(capturedRetryWith)
    }

    /// `send(_:)` re-sends the request via `retryWith` when a response handler calls it, and
    /// the final response from the retried request is returned to the caller.
    func test_sendRequest_responseHandler_retryWithReSendsRequest() async throws {
        let redirectResponse = HTTPResponse.success(statusCode: 302)
        let finalResponse = HTTPResponse.success(statusCode: 200)

        let responseHandler = RedirectFollowingResponseHandler()

        subject = HTTPService(
            baseURL: URL(string: "https://example.com")!,
            client: client,
            responseHandlers: [responseHandler],
        )

        client.results = [
            .success(redirectResponse),
            .success(finalResponse),
        ]

        let httpRequest = HTTPRequest(url: URL(string: "https://example.com")!)
        let result = try await subject.send(httpRequest)

        XCTAssertEqual(result.statusCode, 200)
        XCTAssertEqual(client.requests.count, 2)
    }

    /// `send(_:)` throws the error encountered when validating the response.
    func test_sendRequest_validatesResponse() async {
        let response = HTTPResponse.failure(statusCode: 400)
        client.result = .success(response)

        do {
            _ = try await subject.send(TestRequest())
            XCTFail("Expected send(_:) to throw an error")
        } catch {
            XCTAssertEqual(error as? TestError, .invalidResponse)
        }
    }
}

private struct RequestError: Error {}

/// A `ResponseHandler` that captures the `retryWith` closure passed to it for inspection in tests.
@MainActor
private class CapturingRetryWithResponseHandler: ResponseHandler {
    var onHandle: (((HTTPRequest) async throws -> HTTPResponse)?) -> Void

    init(onHandle: @escaping (((HTTPRequest) async throws -> HTTPResponse)?) -> Void) {
        self.onHandle = onHandle
    }

    func handle(
        _ response: inout HTTPResponse,
        for request: HTTPRequest,
        retryWith: ((HTTPRequest) async throws -> HTTPResponse)?,
    ) async throws -> HTTPResponse {
        onHandle(retryWith)
        return response
    }
}

/// A `ResponseHandler` that follows a 302 redirect by calling `retryWith` with the original request.
@MainActor
private class RedirectFollowingResponseHandler: ResponseHandler {
    func handle(
        _ response: inout HTTPResponse,
        for request: HTTPRequest,
        retryWith: ((HTTPRequest) async throws -> HTTPResponse)?,
    ) async throws -> HTTPResponse {
        guard response.statusCode == 302, let retryWith else {
            return response
        }
        return try await retryWith(request)
    }
}
