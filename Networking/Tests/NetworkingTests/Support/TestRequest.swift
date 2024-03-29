import Foundation

@testable import Networking

struct TestRequest: Request {
    typealias Response = TestResponse
    let path = "/test"

    func validate(_ response: HTTPResponse) throws {
        switch response.statusCode {
        case 400:
            throw TestError.invalidResponse
        default:
            return
        }
    }
}

struct TestResponse: Response {
    let httpResponse: HTTPResponse
    init(response: HTTPResponse) throws {
        httpResponse = response
    }
}

struct TestJSONRequest: Request {
    typealias Response = TestJSONResponse
    let path = "/test.json"
}

struct TestJSONResponse: JSONResponse {
    static var decoder: JSONDecoder { JSONDecoder() }

    var field: String
}

struct TestValidatingRequest: Request {
    typealias Response = TestResponse
    let path = "/test"

    func validate(_ response: HTTPResponse) throws -> Result<HTTPResponse, Error> {
        throw TestError.badResponse
    }
}

struct TestJSONRequestBody: JSONRequestBody {
    static var encoder: JSONEncoder { JSONEncoder() }

    let field: String
}

struct TestJSONBodyRequest: Request {
    typealias Response = TestResponse
    typealias Body = TestJSONRequestBody
    let path = "/test"

    var body: TestJSONRequestBody?
}
