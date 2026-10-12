import Networking

/// A `ResponseHandler` that follows a 302 redirect by calling `retryWith` with the original request.
@MainActor
class RedirectFollowingResponseHandler: ResponseHandler {
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
