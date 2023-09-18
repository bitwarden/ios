import Networking

class TestRequestHandler: RequestHandler {
    var handledRequest: HTTPRequest?
    var requestHandler: ((inout HTTPRequest) -> Void)?

    init(_ requestHandler: ((inout HTTPRequest) -> Void)?) {
        self.requestHandler = requestHandler
    }

    func handle(_ request: inout HTTPRequest) async throws -> HTTPRequest {
        handledRequest = request
        requestHandler?(&request)
        return request
    }
}
