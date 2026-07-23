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
    func test_init_defaultValues() {
        let subject = HTTPRequest(url: URL(string: "https://example.com")!)

        XCTAssertNil(subject.body)
        XCTAssertEqual(subject.headers, [:])
        XCTAssertEqual(subject.method, .get)
        XCTAssertEqual(subject.url, URL(string: "https://example.com")!)
    }

    /// The initializer sets the item's properties.
    func test_init() throws {
        let subject = HTTPRequest(
            url: URL(string: "https://example.com/json")!,
            method: .post,
            headers: [
                "Content-Type": "application/json",
                "Authorization": "🔒",
            ],
            body: "top secret".data(using: .utf8)!,
        )

        try XCTAssertEqual(
            String(data: XCTUnwrap(subject.body), encoding: .utf8),
            "top secret",
        )
        XCTAssertEqual(
            subject.headers,
            [
                "Content-Type": "application/json",
                "Authorization": "🔒",
            ],
        )
        XCTAssertEqual(subject.method, .post)
        XCTAssertEqual(subject.url, URL(string: "https://example.com/json")!)
    }

    /// `init?(from:)` builds a `HTTPRequest` from a `URLRequest`.
    func test_init_fromURLRequest() throws {
        var urlRequest = URLRequest(url: URL(string: "https://example.com/json")!)
        urlRequest.httpMethod = "POST"
        urlRequest.allHTTPHeaderFields = ["Content-Type": "application/json"]
        urlRequest.httpBody = "top secret".data(using: .utf8)

        let subject = try XCTUnwrap(HTTPRequest(from: urlRequest))

        XCTAssertEqual(
            try String(data: XCTUnwrap(subject.body), encoding: .utf8),
            "top secret",
        )
        XCTAssertEqual(subject.headers, ["Content-Type": "application/json"])
        XCTAssertEqual(subject.method, .post)
        XCTAssertEqual(subject.url, URL(string: "https://example.com/json")!)
    }

    /// `init?(from:)` uses GET and empty headers when the `URLRequest` omits them.
    func test_init_fromURLRequest_defaultValues() throws {
        let urlRequest = URLRequest(url: URL(string: "https://example.com")!)

        let subject = try XCTUnwrap(HTTPRequest(from: urlRequest))

        XCTAssertNil(subject.body)
        XCTAssertEqual(subject.headers, [:])
        XCTAssertEqual(subject.method, .get)
        XCTAssertEqual(subject.url, URL(string: "https://example.com")!)
    }

    /// `init?(from:)` returns `nil` when the `URLRequest` has no URL.
    func test_init_fromURLRequest_nilURL() {
        var urlRequest = URLRequest(url: URL(string: "https://example.com")!)
        urlRequest.url = nil

        XCTAssertNil(HTTPRequest(from: urlRequest))
    }

    /// `init(request:baseURL)` builds a `HTTPRequest` from a `Request` object.
    func test_init_request() throws {
        let subject = try HTTPRequest(
            request: TestRequest(),
            baseURL: URL(string: "https://example.com/")!,
        )

        XCTAssertEqual(
            try String(data: XCTUnwrap(subject.body), encoding: .utf8),
            "body data",
        )
        XCTAssertEqual(subject.headers, ["Content-Type": "application/json"])
        XCTAssertEqual(subject.method, .get)
        XCTAssertEqual(subject.url, URL(string: "https://example.com/test?foo=bar")!)
    }
}
