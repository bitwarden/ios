import XCTest

@testable import Networking

class RequestTests: XCTestCase {
    struct DefaultRequest: Request {
        typealias Response = String // swiftlint:disable:this nesting
        var path: String = "/path"
    }

    /// `Request` default.
    func test_request() {
        let request = DefaultRequest()
        XCTAssertEqual(request.method, .get)
        XCTAssertNil(request.body)
        XCTAssertEqual(request.headers, [:])
        XCTAssertEqual(request.query, [])
    }
}
