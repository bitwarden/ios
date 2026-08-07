import Networking

/// A `ResponseHandler` that captures the `retryWith` closure passed to it for inspection in tests.
@MainActor
class CapturingRetryWithResponseHandler: ResponseHandler {
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
