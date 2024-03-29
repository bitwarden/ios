import XCTest

@testable import Networking

class HTTPRequestTests: XCTestCase {
    struct TestRequest: Request {
        typealias Response = String // swiftlint:disable:this nesting
        let body: Data? = "body data".data(using: .utf8)
        let headers = ["Content-Type": "application/json"]
        let method = HTTPMethod.get
        let path = "/test"
        let query = [URLQueryItem(name: "foo", value: "bar")]
    }

    /// The initializer provides default values.
    func testInitDefaultValues() {
        let subject = HTTPRequest(url: URL(string: "https://example.com")!)

        XCTAssertNil(subject.body)
        XCTAssertEqual(subject.headers, [:])
        XCTAssertEqual(subject.method, .get)
        XCTAssertEqual(subject.url, URL(string: "https://example.com")!)
    }

    /// The initializer sets the item's properties.
    func testInit() throws {
        let subject = HTTPRequest(
            url: URL(string: "https://example.com/json")!,
            method: .post,
            headers: [
                "Content-Type": "application/json",
                "Authorization": "🔒",
            ],
            body: "top secret".data(using: .utf8)!
        )

        try XCTAssertEqual(
            String(data: XCTUnwrap(subject.body), encoding: .utf8),
            "top secret"
        )
        XCTAssertEqual(
            subject.headers,
            [
                "Content-Type": "application/json",
                "Authorization": "🔒",
            ]
        )
        XCTAssertEqual(subject.method, .post)
        XCTAssertEqual(subject.url, URL(string: "https://example.com/json")!)
    }

    /// `init(request:baseURL)` builds a `HTTPRequest` from a `Request` object.
    func testInitRequest() throws {
        let subject = try HTTPRequest(
            request: TestRequest(),
            baseURL: URL(string: "https://example.com/")!
        )

        XCTAssertEqual(
            try String(data: XCTUnwrap(subject.body), encoding: .utf8),
            "body data"
        )
        XCTAssertEqual(subject.headers, ["Content-Type": "application/json"])
        XCTAssertEqual(subject.method, .get)
        XCTAssertEqual(subject.url, URL(string: "https://example.com/test?foo=bar")!)
    }
}
