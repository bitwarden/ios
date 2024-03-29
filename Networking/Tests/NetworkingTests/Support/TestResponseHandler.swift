import Networking

class TestResponseHandler: ResponseHandler {
    var handledResponse: HTTPResponse?
    var responseHandler: ((inout HTTPResponse) -> Void)?

    init(_ responseHandler: ((inout HTTPResponse) -> Void)?) {
        self.responseHandler = responseHandler
    }

    func handle(_ response: inout HTTPResponse) async throws -> HTTPResponse {
        handledResponse = response
        responseHandler?(&response)
        return response
    }
}
