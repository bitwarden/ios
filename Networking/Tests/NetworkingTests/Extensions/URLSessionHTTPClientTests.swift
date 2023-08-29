import XCTest

@testable import Networking

class URLSessionHTTPClientTests: XCTestCase {
    var subject: URLSession!

    override func setUp() {
        super.setUp()

        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]

        subject = URLSession(configuration: configuration)
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
        URLProtocolMocking.reset()
    }

    /// `send(_:)` performs the request and returns the response for a 200 status request.
    func testSendSuccess200() async throws {
        let urlResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!

        URLProtocolMocking.mock(
            HTTPRequest.default.url,
            with: .success((urlResponse, "response data".data(using: .utf8)!))
        )

        let httpResponse = try await subject.send(.default)

        XCTAssertEqual(
            try String(data: XCTUnwrap(httpResponse.body), encoding: .utf8),
            "response data"
        )
        XCTAssertEqual(httpResponse.headers, ["Content-Type": "application/json"])
        XCTAssertEqual(httpResponse.statusCode, 200)
        XCTAssertEqual(httpResponse.url, URL(string: "https://example.com")!)
    }

    /// `send(_:)` performs the request and returns the response for a 500 status request.
    func testSendSuccess500() async throws {
        let urlResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )!

        URLProtocolMocking.mock(
            HTTPRequest.default.url,
            with: .success((urlResponse, Data()))
        )

        let httpResponse = try await subject.send(.default)

        XCTAssertEqual(httpResponse.body, Data())
        XCTAssertEqual(httpResponse.headers, [:])
        XCTAssertEqual(httpResponse.statusCode, 500)
        XCTAssertEqual(httpResponse.url, URL(string: "https://example.com")!)
    }

    /// `send(_:)` performs the request and throws an error if one occurs.
    func testSendError() async throws {
        URLProtocolMocking.mock(
            HTTPRequest.default.url,
            with: .failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil))
        )

        do {
            _ = try await subject.send(.default)
            XCTFail("Expected send(_:) to throw an error.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, NSURLErrorDomain)
            XCTAssertEqual(nsError.code, NSURLErrorTimedOut)
        }
    }
}
